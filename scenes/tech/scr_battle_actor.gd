extends Node2D
class_name BattleActor

# base class for battle actors

const WAIT_AFTER_ATTACK := 1.0
const WAIT_AFTER_SPIRIT := 1.0
const WAIT_AFTER_SPIRIT_MULTI_ATTACK := 0.1
const WAIT_AFTER_ITEM := 1.00
const WAIT_AFTER_FLEE := 1.0

static var player_speed_modifier := 1.0

signal message(msg: String, options: Dictionary)
signal act_requested(by_whom: BattleActor)
signal act_finished(by_whom: BattleActor)
signal player_input_requested(by_whom: BattleActor)
signal died(who: BattleActor)
signal fled(who: BattleActor)
signal teammate_requested(who: BattleActor, whom: String)
signal critically_hitted

enum States {IDLE = -1, COOLDOWN, ACTING, DEAD}
var state: States = States.IDLE: set = set_state

var turn := 0

var hurt_sound := preload("res://sounds/hurt.ogg")

var actor_name: StringName
@onready var character: Character

var accessible := true

var status_effects: Array[BattleStatusEffect]

var reference_to_team_array: Array[BattleActor] = []
var reference_to_opposing_array: Array[BattleActor] = []
var reference_to_actor_array: Array[BattleActor] = []

var player_controlled := false

@export_group("Other")
@export_enum(
	"None", "Electric",
	"Sopping", "Burning",
	"Ghost", "Brain", "Vast"
	) var gender: int = 0
@export var effect_immunities: Array[String] = []
@export_range(0.0, 1.0) var stat_multiplier: = 1.0
@export var wait := 1.0


# battle script accesses actors through the group
func _init() -> void:
	self.add_to_group("battle_actors")


# the character is loaded before _ready()
func _ready() -> void:
	if not is_instance_valid(character):
		character = Character.new()
	actor_name = character.name


func _process(delta: float) -> void:
	var sleepy := has_status_effect(&"sleepy")
	if not character: return
	if SOL.dialogue_open: return # don't run logic if dialogue is open
	effect_visuals()
	match state:
		States.IDLE:
			pass
		States.COOLDOWN:
			# cooldown between 1 and 0 usually
			# older system ported from old greg
			# always calculated based on fastest party member
			var ratio := delta * (player_speed_modifier)
			wait = maxf(wait - maxf(ratio * get_speed(), 0.1 * delta), 0.0)
			if wait == 0.0:
				if not sleepy:
					act_requested.emit(self)
					set_state(States.ACTING)
					wait = 1.0
				else:
					status_effect_update()
					SOL.vfx(
						"sleepy",
						global_position + Vector2(randf_range(-4, 4),
							randf_range(-16, 0)), {"parent": self})
					wait = 1.0
					if sleepy:
						emit_message("%s is sleeping..." % actor_name)
						SND.play_sound(preload("res://sounds/sleepy.ogg"),
						 {"volume": 6})
					else:
						emit_message("%s woke up." % actor_name)
		States.ACTING:
			pass
		States.DEAD:
			pass


func act() -> void:
	set_state(States.ACTING)
	if player_controlled:
		player_input_requested.emit(self)
		return


func set_state(to: States) -> void:
	if not state == States.DEAD:
		state = to


func heal(amount: float) -> void:
	if state == States.DEAD: return
	# limit healing to max health
	character.health = minf(character.health + absf(amount), character.max_health)
	SOL.vfx("damage_number", parentless_effcenter(self), {text = absf(roundi(amount)), color=Color.GREEN_YELLOW})


func hurt(amt: float, gendr: int) -> void:
	var amount := amt
	amount = Genders.apply_gender_effects(amount, self, gendr)
	if state == States.DEAD: return
	for x: BattleStatusEffect in status_effects:
		amount += x.hurt_damage(amount, gendr, self)
	amount = maxf(amount, 1.0)
	character.health = maxf(character.health - absf(amount), 0.0)
	if character.health <= 0.0:
		state = States.DEAD
		SND.play_sound(preload("res://sounds/hurt.ogg"), {"pitch_scale": 0.5, "volume": 4})
		died.emit(self)
	else:
		# hurt sound
		if randf() < 0.0001 and actor_name == "greg":
			SND.play_sound(preload("res://sounds/eek.ogg"))
		else:
			SND.play_sound(
				hurt_sound,
				{"pitch_scale": maxf(lerpf(2.0, 0.5, remap(
					amount, 1, 90, 0.1, 1)), 0.1),
				"volume": randi_range(-4, 1)}
			)

	# damage number
	SOL.vfx(
		"damage_number",
		parentless_effcenter(self),
		{text = absf(roundi(amount)),
		color = Color.RED,
		})
	# shake the screen (not visible unless high damage)
	SOL.shake(sqrt(amount)/15.0)


func flee() -> void:
	SND.play_sound(preload("res://sounds/flee.ogg"))
	SOL.vfx("damage_number", get_effect_center(self), {text = "bye!", color=Color.WHITE})
	# so that it won't be acting anymore
	set_state(States.DEAD)
	fled.emit(self)
	emit_message("%s vacates the scene" % [actor_name])
	await get_tree().create_timer(WAIT_AFTER_FLEE).timeout
	turn_finished()


func get_attack() -> float:
	var x := 0.0
	x += character.get_stat("attack")
	if has_status_effect(&"attack"):
		x += get_status_effect(&"attack").strength
	return maxf(x, 1) * stat_multiplier


func get_defense() -> float:
	var x := 0.0
	x += character.get_stat("defense")
	if has_status_effect(&"defense"):
		x += get_status_effect(&"defense").strength
	return maxf(x, 1) * stat_multiplier


func get_speed() -> float:
	var x := 0.0
	x += character.get_stat("speed")
	if has_status_effect(&"speed"):
		x += get_status_effect(&"speed").strength
	if has_status_effect(&"little"):
		x *= 0.25
	return maxf(x, 1) * stat_multiplier


static func calc_attack_damage(atk: float, random := true) -> float:
	var x := 0.0
	x += atk
	if random: x += randf() * 2
	# funny level-based damage calculation
	var y := roundf(Math.method_29193(x))
	return y


# the half of defense is subtracted from the attack damage
func account_defense(x: float) -> float:
	var def := get_defense()
	var result := maxf(abs(x) - (def**0.77), 0)
	return roundf(result)


func attack(subject: BattleActor) -> void:
	if not subject.accessible:
		SND.play_sound(preload("res://sounds/flee.ogg"))
		SOL.vfx("damage_number", get_effect_center(self), {text = "miss!", color=Color.WHITE})
		await get_tree().create_timer(WAIT_AFTER_ATTACK).timeout
		turn_finished()
		return
	# manual construction of payload
	var crit := randf() <= 0.05
	var pld := payload().set_health(-BattleActor.calc_attack_damage(get_attack()))
	if crit: pld.health *= 2.5
	if gender:
		pld.gender = gender
	var weapon: Item
	if character.weapon:
		# manually copy over stuff from the item's payload
		weapon = DAT.get_item(character.weapon)
		pld.set_defense_pierce(weapon.payload.pierce_defense)
		pld.effects = weapon.payload.effects
		pld.delay = weapon.payload.delay
		pld.animation_on_receive = weapon.payload.animation_on_receive
		if weapon.payload.gender:
			pld.gender = weapon.payload.gender
	subject.handle_payload(pld) # the actual attack
	if crit:
		SOL.vfx(
			"damage_number",
			parentless_effcenter(subject),
			{text = "crit!!!",
			color = Color(1.0, 0.3, 0.2),
		})
		SND.play_sound(preload("res://sounds/critical_hit.ogg"), {"volume": 5})
		critically_hitted.emit()
	# functions just in case
	if self.has_method("_attacked_%s" % subject.character.name_in_file):
		call("_attacked_%s" % subject.character.name_in_file)
	if subject.has_method("_hurt_by_%s" % character.name_in_file):
		call("_hurt_by_%s" % character.name_in_file)
	# animations
	if weapon != null and weapon.attack_animation.length() > 0:
		SOL.vfx(weapon.attack_animation, get_effect_center(subject), {parent = subject})
	else:
		blunt_visuals(subject)
	emit_message("%s attacked %s" % [actor_name, subject.actor_name])
	await get_tree().create_timer(WAIT_AFTER_ATTACK).timeout
	turn_finished()


func use_spirit(id: String, subject: BattleActor) -> void:
	var spirit: Spirit = DAT.get_spirit(id)
	character.magic = max(character.magic - spirit.cost, 0)
	emit_message("%s: %s!" % [actor_name, spirit.name])
	# animating
	if spirit.animation:
		SOL.vfx(spirit.animation, Vector2())
	if spirit.use_animation:
		SOL.vfx(spirit.use_animation, get_effect_center(self))
	# who should be targeted by the spirit
	var targets: Array[BattleActor]
	if spirit.reach == Spirit.Reach.TEAM:
		targets = subject.get_team().duplicate()
	elif spirit.reach == Spirit.Reach.ALL:
		targets = reference_to_actor_array.duplicate()
	else:
		targets = [subject]
	# functions
	if self.has_method("_used_spirit_%s" % id):
		call("_used_spirit_%s" % id)
	# loop through all
	for receiver in targets:
		if character.health <= 0: break
		if spirit.receive_animation:
			SOL.vfx(spirit.receive_animation, get_effect_center(receiver), {parent = receiver})
		for i in spirit.payload_reception_count:
			if character.health <= 0: break
			if receiver.character.health <= 0: break
			receiver.handle_payload(
				spirit.payload.set_sender(self).\
				set_defense_pierce(spirit.payload.pierce_defense if spirit.payload.pierce_defense else 1.0)\
				.set_type(BattlePayload.Types.SPIRIT)
			)
			# we wait a bit before applying the payload again
			await get_tree().create_timer(
				maxf((maxf(WAIT_AFTER_SPIRIT - 0.8, 0.2)) /
				float(spirit.payload_reception_count), 0.01)
			).timeout
		# function
		if receiver.has_method("_spirit_%s_used_on" % id):
			receiver.call("_spirit_%s_used_on" % id)

	await get_tree().create_timer(WAIT_AFTER_SPIRIT).timeout
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	turn_finished()


func use_item(id: String, subject: BattleActor) -> void:
	if not subject.accessible:
		SND.play_sound(preload("res://sounds/flee.ogg"))
		SOL.vfx("damage_number", get_effect_center(self), {text = "miss!", color=Color.WHITE})
		await get_tree().create_timer(WAIT_AFTER_ITEM).timeout
		turn_finished()
		return
	var item: Item = DAT.get_item(id)
	if not (item.use == Item.Uses.WEAPON or item.use == Item.Uses.ARMOUR):
		subject.handle_payload(item.payload.set_sender(self).\
		set_type(BattlePayload.Types.ITEM)) # using the item
		SOL.vfx("use_item", get_effect_center(subject), {parent = subject, item_texture = item.texture, silent = item.play_sound != null})
		if item.play_sound:
			SND.play_sound(item.play_sound)

	else:
		# if it's weapon or armour, equip it
		subject.character.handle_item(id)
	if item.consume_on_use:
		character.inventory.erase(id)
	emit_message("%s used %s" % [actor_name, item.name] if subject == self else "%s used %s on %s" % [actor_name, item.name, subject.actor_name])
	# function
	if subject.has_method("_item_%s_used_on" % id):
		subject.call("_item_%s_used_on" % id)

	await get_tree().create_timer(WAIT_AFTER_ITEM).timeout
	turn_finished()


# squeeze empty the payload, copy everything over
func handle_payload(pld: BattlePayload) -> void:
	print(actor_name, " handling payload! (%s)" % BattlePayload.Types.find_key(pld.type))
	# this somehow fixes a battle end doubling bug. cool.
	await get_tree().process_frame
	if character.health <= 0: return
	if pld.delay: await get_tree().create_timer(pld.delay).timeout
	var health_change := 0.0
	health_change += pld.health
	health_change += (pld.health_percent / 100.0) * character.health
	health_change += (pld.max_health_percent / 100.0) * character.max_health
	if health_change:
		if health_change > 0:
			if gender:
				if pld.gender == gender:
					health_change *= 1.5
			heal(health_change)
		else:
			health_change = absf(health_change)
			health_change = lerpf(account_defense(health_change), health_change, pld.pierce_defense)
			if has_status_effect(&"shield"):
				health_change *= 0.33 - (get_status_effect(&"shield").strength * 0.01)
				SOL.vfx("ribbed_shield", get_effect_center(self), {parent = self})
			hurt(health_change, pld.gender)
			if pld.steal_health and is_instance_valid(pld.sender):
				pld.sender.heal(health_change * pld.steal_health)
			if pld.steal_magic and is_instance_valid(pld.sender):
				pld.sender.character.magic += pld.steal_magic
				character.magic = maxf(character.magic - pld.steal_magic, 0.0)
			if character.health <= 0:
				if is_instance_valid(pld.sender):
					pld.sender.character.add_defeated_character(character.name_in_file)

	character.magic += pld.magic + (pld.magic_percent / 100.0 * character.magic) + (pld.max_magic_percent / 100.0 * character.max_magic)

	for en in pld.effects:
		if en.name.length() and en.duration:
			add_status_effect(en)

	if pld.summon_enemy:
		teammate_requested.emit(self, pld.summon_enemy)

	if pld.meta.get("reveal_enemy_info", false) and pld.sender.player_controlled:
		SOL.dialogue_box.dial_concat("battle_inspect", 1, [actor_name])
		SOL.dialogue_box.dial_concat("battle_inspect", 2, [character.level])
		SOL.dialogue_box.dial_concat("battle_inspect", 3, [get_attack(), get_defense(), get_speed()])
		SOL.dialogue_box.dial_concat("battle_inspect", 4, [character.info if character.info else "secretive one... nothing else could be found."])
		SOL.dialogue("battle_inspect")

	if pld.meta.get("skateboard", false):
		emit_message("woah! skateboard!! so cool!!")
	if pld.meta.get("cellphone", false):
		if character.name_in_file == &"greg":
			SOL.dialogue("phone_dial")
			SOL.dialogue("phone_in_battle")
			SOL.dialogue("phone_call_over")
		else:
			SOL.dialogue_box.dial_concat("phone_in_battle_other_character", 0, [actor_name])
			SOL.dialogue("phone_in_battle_other_character")

	if pld.animation_on_receive:
		SOL.vfx(pld.animation_on_receive, get_effect_center(self), {parent = self})

# STATUS EFFECTS


func add_status_effect(eff: StatusEffect) -> void:
	var effect := BattleStatusEffect.add(self, eff)
	if effect:
		status_effects.append(effect)
		print("added effect ", effect, " to ", self)


func add_status_effect_s(nimi: StringName, strength: float, duration: int) -> void:
	add_status_effect(
		StatusEffect.new().set_effect_name(nimi).set_strength(strength).set_duration(duration)
	)


func has_status_effect(nimi: StringName) -> bool:
	for eff in status_effects:
		if nimi == eff.name:
			return true
	return false


func get_status_effect(nimi: StringName) -> BattleStatusEffect:
	for eff in status_effects:
		if nimi == eff.name:
			return eff
	return null


func remove_status_effect(nimi: StringName) -> void:
	for eff in status_effects:
		if nimi == eff.name:
			eff.removed(self)
			status_effects.erase(eff)
			print("removed effect ", eff, " from ", self)


func status_effect_update() -> void:
	for eff in status_effects:
		eff.turn(self)
		# remove if immune
		if is_immune_to(eff.name):
			remove_status_effect(eff.name)
		print(self, ": ", eff)


func is_immune_to(what: StringName) -> bool:
	if has_status_effect(&"sopping") and what == &"fire":
		return true
	return what in effect_immunities or has_status_effect(what + &"_immunity")


func effect_visuals() -> void:
	for eff in status_effects:
		eff.visuals(self)

# HELPERS


func turn_finished() -> void:
	act_finished.emit(self)
	status_effect_update()
	turn += 1


func load_character(id: StringName) -> void:
	var charc: Character = DAT.get_character(id).duplicate(true)
	character = charc
	charc.defeated_characters.clear()


# at the end of the fight, the party will update changes to their characters
# so that the health and other information will get saved between battles
func offload_character() -> void:
	character.health = maxf(character.health, 1.0)
	var basechar: Character = DAT.character_dict[character.name_in_file]
	basechar.health = character.health
	basechar.magic = clampf(character.magic, 0.0, basechar.max_magic)
	basechar.inventory = character.inventory
	basechar.weapon = character.weapon
	basechar.armour = character.armour
	basechar.add_defeated_characters(character.defeated_characters)


func payload() -> BattlePayload:
	return BattlePayload.new().set_sender(self)


# for positioning visual effects
func get_effect_center(subject: BattleActor = self) -> Vector2:
	return Vector2(subject.effect_center) + Vector2(subject.global_position) if has_effcenter(subject) else subject.get_global_transform_with_canvas().origin
	#return subject.get_global_transform_with_canvas().origin


func has_effcenter(subject: BattleActor = self) -> bool:
	return "effect_center" in subject


# for properly positioning visual effects when not parenting to the actor
func parentless_effcenter(subject: BattleActor = self) -> Vector2:
	if has_effcenter(subject):
		return get_effect_center(subject)
	return get_effect_center(subject) - (SOL.HALF_SCREEN_SIZE)


func emit_message(msg: String, options := {}) -> void:
	message.emit(msg, options)


func get_team() -> Array[BattleActor]:
	return reference_to_team_array


func blunt_visuals(subject: BattleActor) -> void:
	SOL.vfx("dustpuff", get_effect_center(subject), {parent = subject})
	SOL.vfx("bangspark", get_effect_center(subject), {parent = subject, random_rotation = true})
	SND.play_sound(preload("res://sounds/attack_blunt.ogg"))


func _to_string() -> String:
	return actor_name
