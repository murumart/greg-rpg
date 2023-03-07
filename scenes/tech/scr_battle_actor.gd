extends Node2D
class_name BattleActor

const WAIT_AFTER_ATTACK := 1.0
const WAIT_AFTER_SPIRIT := 1.0
const WAIT_AFTER_SPIRIT_MULTI_ATTACK := 0.1
const WAIT_AFTER_ITEM := 1.00
const WAIT_AFTER_FLEE := 1.0

signal message(msg: String)
signal act_requested(by_whom: BattleActor)
signal act_finished(by_whom: BattleActor)
signal player_input_requested(by_whom: BattleActor)
signal died(who: BattleActor)
signal fled(who: BattleActor)

enum States {IDLE = -1, COOLDOWN, ACTING, DEAD}
var state : States = States.IDLE : set = set_state

var turn := 0

var actor_name : StringName
@onready var character : Character

var status_effects : Dictionary = {}

var reference_to_team_array : Array[BattleActor] = []
var reference_to_opposing_array : Array[BattleActor] = []
var reference_to_actor_array : Array[BattleActor] = []

var player_controlled := false


@export_group("Other")
@export_range(0.0, 1.0) var stat_multiplier: = 1.0
@export var wait := 1.0


func _init() -> void:
	self.add_to_group("battle_actors")


func _ready() -> void:
	if not is_instance_valid(character):
		character = Character.new()
	actor_name = character.name


func _physics_process(delta: float) -> void:
	if not character: return
	if SOL.dialogue_open: return
	match state:
		States.IDLE:
			pass
		States.COOLDOWN:
			wait = maxf(wait - sqrt(delta * get_speed() * 0.1), 0.0)
			if wait == 0.0:
				act_requested.emit(self)
				set_state(States.ACTING)
		States.ACTING:
			pass
		States.DEAD:
			pass


func act() -> void:
	set_state(States.ACTING)
	wait = 1.0
	if player_controlled:
		player_input_requested.emit(self)
		return


func set_state(to: States) -> void:
	if not state == States.DEAD:
		state = to


func heal(amount: float) -> void:
	character.health = minf(character.health + absf(amount), character.max_health)
	SOL.vfx("damage_number", get_effect_center(self), {text = absf(amount), color=Color.GREEN_YELLOW})


func hurt(amount: float) -> void:
	character.health = maxf(character.health - absf(amount), 0.0)
	if character.health <= 0.0:
		state = States.DEAD
		SND.play_sound(preload("res://sounds/snd_hurt.ogg"), {"pitch": 0.5, "volume": 4})
		died.emit(self)
	else:
		SND.play_sound(preload("res://sounds/snd_hurt.ogg"), {"pitch": lerpf(2.0, 0.5, remap(amount, 1, 90, 0, 1)), "volume": randi_range(2, 4)})
	SOL.vfx("damage_number", get_effect_center(self), {text = absf(roundi(amount)), color=Color.RED})
	SOL.shake(sqrt(amount)/15.0)


func flee() -> void:
	SND.play_sound(preload("res://sounds/snd_flee.ogg"))
	SOL.vfx("damage_number", get_effect_center(self), {text = "bye!", color=Color.WHITE})
	set_state(States.DEAD)
	fled.emit(self)
	emit_message("%s vacates the scene" % [actor_name])
	await get_tree().create_timer(WAIT_AFTER_FLEE).timeout
	turn_finished()


func get_attack() -> float:
	var x := 0.0
	x += character.get_stat("attack")
	if status_effects.get("attack", {}):
		x += status_effects.get("attack").get("strength")
	return maxf(x, 1) * stat_multiplier


func get_defense() -> float:
	var x := 0.0
	x += character.get_stat("defense")
	if status_effects.get("defense", {}):
		x += status_effects.get("defense").get("strength")
	return maxf(x, 1) * stat_multiplier


func get_speed() -> float:
	var x := 0.0
	x += character.get_stat("speed")
	if status_effects.get("speed", {}):
		x += status_effects.get("speed").get("strength")
	return maxf(x, 1) * stat_multiplier


static func calc_attack_damage(atk: float, random := true) -> float:
	var x := 0.0
	x += atk
	if random: x += randf() * 2
	var y := roundf(Math.method_29193(x))
	return y


func account_defense(x: float) -> float:
	var def := get_defense()
	var result := maxf(abs(x) - sqrt(def), 1)
	return roundf(result)


func attack(subject: BattleActor) -> void:
	var pld := payload().set_health(-BattleActor.calc_attack_damage(get_attack()))
	if character.weapon:
		var weapon : Item = DAT.get_item(character.weapon)
		pld.set_defense_pierce(weapon.payload.pierce_defense)
		pld.set_confusion(weapon.payload.confusion_time)
		pld.set_coughing(weapon.payload.coughing_level, weapon.payload.coughing_time)
		pld.set_poison(weapon.payload.poison_level, weapon.payload.poison_time)
	subject.handle_payload(pld)
	SOL.vfx("dustpuff", get_effect_center(subject), {parent = subject})
	SOL.vfx("bangspark", get_effect_center(subject), {parent = subject, random_rotation = true})
	SND.play_sound(preload("res://sounds/snd_attack_blunt.ogg"))
	emit_message("%s attacked %s" % [actor_name, subject.actor_name])
	
	await get_tree().create_timer(WAIT_AFTER_ATTACK).timeout
	turn_finished()


func use_spirit(id: String, subject: BattleActor) -> void:
	var spirit : Spirit = DAT.get_spirit(id)
	character.magic = max(character.magic - spirit.cost, 0)
	emit_message("%s: %s!" % [actor_name, spirit.name])
	# animating
	if spirit.animation:
		SOL.vfx(spirit.animation, Vector2())
	if spirit.use_animation:
		SOL.vfx(spirit.use_animation, get_effect_center(self))
	# who should be targeted by the spirit
	var targets : Array[BattleActor]
	if spirit.reach == Spirit.Reach.TEAM:
		targets = subject.get_team().duplicate()
	elif spirit.reach == Spirit.Reach.ALL:
		targets = reference_to_actor_array.duplicate()
	else:
		targets = [subject]
	# all targets
	for receiver in targets:
		if spirit.receive_animation:
			SOL.vfx(spirit.receive_animation, get_effect_center(receiver), {parent = receiver})
		for i in spirit.payload_reception_count:
			receiver.handle_payload(spirit.payload.set_sender(self).set_defense_pierce(1.0))
			# we wait a bit before applying the payload again
			await get_tree().create_timer(
					(maxf(WAIT_AFTER_SPIRIT - 0.8, 0.2)) / float(spirit.payload_reception_count)
			).timeout
	
	await get_tree().create_timer(WAIT_AFTER_SPIRIT).timeout
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	turn_finished()


func use_item(id: String, subject: BattleActor) -> void:
	var item : Item = DAT.get_item(id)
	if not (item.use == Item.Uses.WEAPON or item.use == Item.Uses.ARMOUR):
		subject.handle_payload(item.payload.set_sender(self))
		SOL.vfx("use_item", get_effect_center(subject), {parent = subject, item_texture = item.texture})
	else:
		subject.character.handle_item(id)
	if item.consume_on_use:
		character.inventory.erase(id)
	emit_message("%s used %s" % [actor_name, item.name] if subject == self else "%s used %s on %s" % [actor_name, item.name, subject.actor_name])
	
	await get_tree().create_timer(WAIT_AFTER_ITEM).timeout
	turn_finished()


func handle_payload(pld: BattlePayload) -> void:
	print(actor_name, " handling payload!")
	await get_tree().process_frame
	if character.health <= 0: return
	
	var health_change := 0.0
	health_change += pld.health
	health_change += pld.health_percent / 100.0 * character.health
	health_change += pld.max_health_percent / 100.0 * character.max_health
	if health_change:
		if health_change > 0:
			heal(health_change)
		else:
			health_change = absf(health_change)
			health_change = lerpf(account_defense(health_change), health_change, pld.pierce_defense)
			hurt(health_change)
			if character.health <= 0:
				if is_instance_valid(pld.sender):
					pld.sender.character.add_defeated_character(character.name_in_file)
	
	character.magic += pld.magic + (pld.magic_percent / 100.0 * character.magic) + (pld.max_magic_percent / 100.0 * character.max_magic)
	
	introduce_status_effect("attack", pld.attack_increase, pld.attack_increase_time)
	introduce_status_effect("defense", pld.defense_increase, pld.defense_increase_time)
	introduce_status_effect("speed", pld.speed_increase, pld.speed_increase_time)
	introduce_status_effect("confusion", 1, pld.confusion_time)
	introduce_status_effect("coughing", pld.coughing_level, pld.coughing_time)
	introduce_status_effect("poison", pld.poison_level, pld.poison_time)
	
	if pld.reveal_enemy_info and pld.sender.player_controlled:
		SOL.dialogue_box.dial_concat("battle_inspect", 1, [actor_name])
		SOL.dialogue_box.dial_concat("battle_inspect", 2, [character.level])
		SOL.dialogue_box.dial_concat("battle_inspect", 3, [get_attack(), get_defense(), get_speed()])
		SOL.dialogue_box.dial_concat("battle_inspect", 4, [character.info if character.info else "secretive one... nothing else could be found."])
		SOL.dialogue("battle_inspect")


func status_effect_update() -> void:
	for e in status_effects.keys():
		var effect : Dictionary = status_effects[e]
		effect["duration"] = effect.get("duration", 1) - 1
		if effect.get("duration", 1) < 1:
			status_effects[e] = {}
		
		if e == "coughing" and effect.get("duration") > 0:
			var cougher := BattleActor.new()
			cougher.character = Character.new()
			cougher.character.attack = effect.get("strength") * 2
			add_child(cougher)
			cougher.attack(self)
			SND.play_sound(preload("res://sounds/spirit/snd_airspace_violation.ogg"), {"volume": -3})
			cougher.queue_free()
		if e == "poison" and effect.get("duration") > 0:
			hurt(effect.get("strength", 1) * 1.3)


func introduce_status_effect(nomen: String, strength: float, duration: int) -> void:
	if not nomen in status_effects.keys():
		status_effects[nomen] = {}
	var old_strength : float = status_effects[nomen].get("strength", 0)
	var old_duration : int = status_effects[nomen].get("duration", 0)
	var new_strength : float = (old_strength + strength / 2.0) if old_strength != 0 else strength
	var new_duration : int = 0 if duration < 0 else roundi((old_duration + duration / 2.0)) if old_duration != 0 else duration
	status_effects[nomen] = {
		"strength": new_strength,
		"duration": new_duration
	}
	if strength and duration:
		SOL.vfx("damage_number", get_effect_center(self), {text = "%s%s %s" % [Math.sign_symbol(strength), str(absf(strength)) if strength != 1 else "", nomen], color = Color.YELLOW, speed = 0.5})


func turn_finished() -> void:
	act_finished.emit(self)
	status_effect_update()
	turn += 1


func load_character(id: String) -> void:
	var charc : Character = DAT.get_character(id).duplicate(true)
	character = charc


func offload_character() -> void:
	character.health = maxf(character.health, 1.0)
	var basechar : Character = DAT.character_dict[character.name_in_file]
	basechar.health = character.health
	basechar.magic = character.magic
	basechar.inventory = character.inventory
	basechar.defeated_characters = character.defeated_characters


func payload() -> BattlePayload:
	return BattlePayload.new().set_sender(self)


func get_effect_center(subject: BattleActor) -> Vector2i:
	return subject.effect_center + Vector2i(subject.global_position) if "effect_center" in subject else Vector2i(subject.global_position)


func emit_message(msg: String) -> void:
	message.emit(msg)


func get_team() -> Array[BattleActor]:
	return reference_to_team_array


func is_confused() -> bool:
	if status_effects.get("confusion", {}):
		if status_effects.get("confusion", {}).get("duration", 0) > 0:
			return true
	return false
