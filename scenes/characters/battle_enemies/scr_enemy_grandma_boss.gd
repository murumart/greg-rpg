extends BattleEnemy

const UNSUITABLE_FOR_BUFFING := ["summon_vacuum", "smallshield"]
const USUAL := preload("res://sprites/characters/battle/grandma/spr_battle.png")
const USE_ITEM := preload("res://sprites/characters/battle/grandma/spr_use_item.png")
const USE_SPIRIT := preload("res://sprites/characters/battle/grandma/spr_use_spirit.png")
const ATTACK := preload("res://sprites/characters/battle/grandma/spr_attack.png")

const FINAL_TURNS := 12

@export var enemy_health_toughness_curve: Curve

@onready var healing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.HEALING) if character else []
@onready var hurting_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.HURTING) if character else []
@onready var buffing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.BUFFING) if character else []
@onready var debuffing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.DEBUFFING) if character else []
@onready var magic_replenishing_items := self.character.inventory.filter(func(a):
		var item := ResMan.get_item(a)
		return (item.payload.get_magic_change(
				character.magic, character.max_magic) > 0
				or item.payload.effects.any(func(b):
					return (b as StatusEffect).name == &"inspiration"))) if character else []

@onready var sprite: Sprite2D = $Sprite
@onready var particles: GPUParticles2D = $Sprite/GPUParticles2D
@onready var final_animation: AnimationPlayer = $AnimationSprite/FinalAnimation
@onready var animation_sprite: AnimatedSprite2D = $AnimationSprite

var progress := 0


func _ready() -> void:
	remove_child(animation_sprite)
	SOL.add_ui_child(animation_sprite)
	animation_sprite.hide()
	super()
	magic_replenishing_items.sort_custom(func(a, b):
		return (ResMan.get_item(a).payload.get_magic_change(character.magic, character.max_magic)
				< ResMan.get_item(b).payload.get_magic_change(
						character.magic, character.max_magic)))
	healing_items.sort_custom(func(a, b):
		return (ResMan.get_item(a).payload.get_health_change(character.health, character.max_health)
				< ResMan.get_item(b).payload.get_health_change(
						character.health, character.max_health))
	)


func turn_actions() -> bool:
	var dbg_skip := false #DEBUG
	await speak_line()
	if should_die:
		progress = FINAL_TURNS + 2
	if progress >= FINAL_TURNS or dbg_skip:
		if progress == FINAL_TURNS:
			accessible = false
			remove_allies()
			await Math.timer(1.0)
			turn_finished()
		elif progress == FINAL_TURNS + 1:
			await Math.timer(1.0)
			turn_finished()
		elif progress == FINAL_TURNS + 2:
			await Math.timer(1.0)
			turn_finished()
		elif progress == FINAL_TURNS + 3 or dbg_skip:
			await Math.timer(0.1)
			_final_attack()
			#turn_finished()
		progress += 1
		return true
	progress += 1
	return false


func ai_action() -> void:
	if await turn_actions():
		return
	if has_status_effect(&"confusion"):
		super()
		return
	var target := pick_target()
	toughness = enemy_health_toughness_curve.sample_baked(
			target.character.health_perc() + get_debuff_severity(self))
	if character.health_perc() <= 1.0 - toughness:
		if health_replenish():
			return
	if target in crittable:
		attack(target)
		return
	if reference_to_team_array.size() < 2:
		if try_use_spirit("summon_vacuum", self):
			return
	if ((not has_status_effect(&"shield") and rng.randf() <= 1.0 - toughness)
			or self in target.crittable):
		if try_use_spirit("smallshield", self):
			return
	if not is_buffed(self) and rng.randf() <= 1.0 - toughness:
		if not buffing_spirits.is_empty() and rng.randf() < 0.67:
			var spirit: String = Math.determ_pick_random(buffing_spirits, rng)
			if suitable_for_buffing(spirit, target):
				if try_use_spirit(spirit, self):
					return
		if not buffing_items.is_empty():
			var item: String = Math.determ_pick_random(buffing_items, rng)
			use_item(item, self)
			return
	if (get_debuff_severity(target) < 0.2 * (1.0 - toughness) and rng.randf() < 0.95
			or target.has_status_effect(&"sleepy") and rng.randf() < 0.89):
		if not debuffing_spirits.is_empty() and rng.randf() < 0.78:
			var spirit: String = Math.determ_pick_random(debuffing_spirits, rng)
			if try_use_spirit(spirit, target):
				return
		if not buffing_items.is_empty():
			var item: String = Math.determ_pick_random(debuffing_items, rng)
			use_item(item, target)
			return
	attack(target)


var should_die := false
func hurt(amount: float, h_gender: int) -> void:
	var actual_damage := _hurt_damage(amount, h_gender)
	if character.health - actual_damage <= 0.0:
		should_die = true
		SND.play_sound(preload("res://sounds/fishing/timeout.ogg"))
		SND.play_song("", 56)
		super(character.health - 1, Genders.NONE)
		var tw := create_tween()
		for x in 20:
			tw.tween_property(sprite, "position:x", 20 - x, 0.005 * x)
			tw.tween_property(sprite, "position:x", -20 + x, 0.005 * x)
		tw.tween_property(sprite, "position:x", 0.0, 0.1)
		return
	super(amount, h_gender)
	if randf() < 0.001:
		heheh_hahah(get_tree().root)


func try_use_spirit(spirit: String, on_whom: BattleActor, replenish_magic := true) -> bool:
	var spirit_instance := ResMan.get_spirit(spirit)
	var enough_magic := spirit_instance.cost <= character.magic
	if not enough_magic:
		if replenish_magic:
			return magic_replenish(spirit_instance.cost)
		return false
	use_spirit(spirit, on_whom)
	return true


func magic_replenish(needed: int) -> bool:
	var found := ""
	for s_item in magic_replenishing_items:
		var item := ResMan.get_item(s_item)
		if (item.payload.get_magic_change(character.magic, character.max_magic)
				+ character.magic >= needed):
			found = s_item
			break
	if not found and (magic_replenishing_items.is_empty() or rng.randf() < 0.25):
		return false
	if not found:
		found = Math.determ_pick_random(magic_replenishing_items, rng)
	use_item(found, self)
	return true


func health_replenish() -> bool:
	if not healing_spirits.is_empty():
		var spirit: String = Math.determ_pick_random(healing_spirits, rng)
		if try_use_spirit(spirit, self, false):
			return true
	var found := ""
	for s_item in healing_items:
		var item := ResMan.get_item(s_item)
		if (item.payload.get_health_change(character.health, character.max_health)
				+ character.health >= character.max_health):
			found = s_item
			break
	if not found and (healing_items.is_empty() or rng.randf() < 0.1):
		return false
	if not found:
		found = healing_items.back()
	use_item(found, self)
	return true


func use_item(item: String, whom: BattleActor) -> void:
	super(item, whom)
	healing_items.erase(item)
	hurting_items.erase(item)
	buffing_items.erase(item)
	debuffing_items.erase(item)
	magic_replenishing_items.erase(item)
	sprite.texture = USE_ITEM
	particles.texture = USE_ITEM
	get_tree().create_timer(0.7).timeout.connect(func():
		sprite.texture = USUAL
		particles.texture = USUAL)


func use_spirit(spirit: String, whom: BattleActor) -> void:
	sprite.texture = USE_SPIRIT
	particles.texture = USE_SPIRIT
	get_tree().create_timer(0.7).timeout.connect(func():
		sprite.texture = USUAL
		particles.texture = USUAL)
	super(spirit, whom)


func get_attack_payload(target: BattleActor) -> BattlePayload:
	var pld := super(target)
	# try not to kill greg too bad
	if target.has_status_effect("confusion"):
		pld.health *= 0.5
	if target.character.health_perc() < 0.125:
		pld.health *= 0.5
	if target.character.health_perc() < 0.0625:
		pld.health *= 0.5
	return pld


func attack(whom: BattleActor) -> void:
	super(whom)
	sprite.texture = ATTACK
	particles.texture = ATTACK
	get_tree().create_timer(0.4).timeout.connect(func():
		sprite.texture = USUAL
		particles.texture = USUAL)


func _item_free_hugs_coupon_used_on() -> void:
	SOL.dialogue("free_hugs_grandma")
	character.attack = 9999999999999
	await SOL.dialogue_closed
	attack(pick_target())


func _lines_by_turn() -> PackedStringArray:
	if should_die:
		return [
			"oh... oh dear...",
			"greg... greg... greg...",
			"you've grown strong, haven't you?",
			"very strong. you almost made me...",
			"well, no matter! it's what i asked you to do.",
			"you have served your purpose very well.",
			"now, it's time to rest for a thousand years.",
			"greg... [color=#ff0]become stone.",
		]
	match progress:
		0: return [
			"talking... love doing it.",
			"is it ok if i beat the crap out of you while we talk?",
			"thanks, dear.",
		]
		1: return [
			"so... here's whats up.",
			"i arrived long ago... came from a much bigger place.",
			"and that felt constricting! limiting! pointless!",
			"i observed the people going about their processes.",
			"and, dear... they were really stupid.",
			"only suffering, inefficiency!",
		]
		3: return [
			"i thought i knew better. so i went in there.",
			"i made my own flowers... and started telling things...",
			"giving people advice, let's say...",
			"the language of flowers is very expressive, you know.",
			"and can be very elevating...",
		]
		4:
			if pick_target().character.inventory.size() > 10:
				return [
					"by the way... all those items you've gathered...",
					"i've been doing some gathering of my own!",
					"so, it's a very fair battle!",
					"fairest than any other thus far!! stop complaining!!",
				]
			return [
				"by the way... while you were slacking off...",
				"i was being vigilant and collecting...",
				"...items to use in battle!",
				"and i won't hold back... if i need to heal, i will!",
			]
		6: return [
			"back to the matter at hand...",
			"there's two mistakes. i've made two mistakes.",
			"first. the processes... the people... they were like that...",
			"because it made sense. because they should be like that.",
			"people have charac- ters! energy trans- forms! cause! effect!",
		]
		7: return [
			"when i went and whispered those things to those people...",
			"there was no longer cause and effect.",
			"there was cause-florist-effect!",
			"what was supposed to happen then?",
			"surprise: nothing good did.",
		]
		8: return [
			"second mistake. forgetting.",
			"...it was more refusal to learn than forgetting.",
			"i gave out more flowers, more, more.",
			"it didn't converge on a likable scenario.",
			"just... more... nonsense.",
			"stretching everything far away from the original purpose.",
		]
		10: return [
			"dear... greg. your flower was the last one.",
			"it gave you what you needed to bring back the others.",
			"the potential to overcome them...",
			"the final nonsense to end all other nonsense...",
			"the biggest instance.",
		]
		11: return [
			"do you even remember you were here for your house, dear?",
			"all the distractions have consumed you.",
			"and me too... i'm in such a hurry.",
			"they'll be here soon to... oh, you shouldn't worry.",
			"i barely sound like an old woman anymore.",
		]
		FINAL_TURNS: return [
			"here's the thing, greg. greggy boy.",
			"i can't just let you go back to the streets.",
			"you're more cause than effect now. i'll do with you...",
			"...what i do with all my good ideas.",
			"note them down.",
			"stop the carnage for now...",
		]
		FINAL_TURNS + 1: return [
			"the perfect medium for storage... is stone.",
			"stone doesn't rot or decay. it remembers even if it changes...",
			"oh, you probably heard all about it in the woods already.",
			"here's my proposition: you live forever... as a piece of stone.",
			"your input on this idea will be your currently fleshy body.",
			"stand still while i charge my [color=ff0]electric! petrification! beam!",
		]
		FINAL_TURNS + 2: return [
			"electric attacks don't hurt that much, do they?",
			"you probably got hit by a few while fighting those...",
			"...appliances... tch... stupid freaks!!",
			"they thought i'd like them more if they looked like cats. ugh...",
			"whatever! next turn you'll feel my [color=ff0]beam!",
		]
		FINAL_TURNS + 3: return [
			"greg... thank you.",
			"thank you for everything.",
			"we'll meet again when you're needed.",
			"see you... in a thousand years or so.",
			"take this! [color=ff0]electric! petrification!! beammm!!!",
		]
	return []


func speak_line() -> void:
	var dlg := DialogueBuilder.new().set_char("grandma")
	for l in _lines_by_turn():
		dlg.al(l)
	if not dlg.is_empty():
		await dlg.speak_choice()


func remove_allies() -> void:
	for c: BattleActor in reference_to_team_array:
		if c != self:
			c.ignore_my_finishes = true
			c.flee()
	SND.play_song("byddd", 0.9)


func _final_attack() -> void:
	SND.play_song("")
	sprite.hide()
	animation_sprite.show()
	var bg := get_tree().get_first_node_in_group("battle_background")
	if bg:
		create_tween().tween_property(bg, "modulate", Color.BLACK, 1.0)
	final_animation.play(&"strike")
	await final_animation.animation_finished
	_end()


func _end() -> void:
	var armour := pick_target().character.armour
	if armour == &"frankling_badge":
		var dlg := DialogueBuilder.new().set_char("grandma")
		dlg.al("huh? what's this now??")
		await dlg.speak_choice()
		final_animation.play("resist")
		await Math.timer(1.5)
		SOL.dialogue_high_position()
		dlg.reset()
		dlg.al("that... that old fool!!")
		dlg.al("you kept his badge??")
		dlg.al("the [color=%s]frankling badge??" % dlg.PRESCOLOR)
		dlg.al("but then, my electric attack...!")
		await dlg.speak_choice()
		final_animation.play("reflect")
		await final_animation.animation_finished
		var t := create_tween()
		SND.play_song("bymsps")
		t.tween_property(SND.current_song_player, ^"pitch_scale", 8.0, 4.0)
		SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 4.0, {free_rect = false})
		await SOL.fade_finished
		SND.play_song("", 999)
		LTS.change_scene_to("res://scenes/rooms/sg/scn_xprefb.tscn")
	else:
		LTS.change_scene_to("res://scenes/cutscene/stone_ending.tscn")


static func is_debuffed(whom: BattleActor) -> bool:
	return (
		whom.get_attack() < whom.character.attack
		or whom.get_defense() < whom.character.defense
		or whom.get_speed() < whom.character.speed
		or whom.has_status_effect(&"sopping")
	)


static func is_buffed(whom: BattleActor) -> bool:
	return (
		whom.get_attack() > whom.character.attack
		or whom.get_defense() > whom.character.defense
		or whom.get_speed() > whom.character.speed
	)


static func get_debuff_severity(whom: BattleActor) -> float:
	var sev := 0.0
	for x in whom.status_effects.values():
		x = x as BattleStatusEffect
		if ((x.type.s_id == &"attack" or x.type.s_id == &"defense" or x.type.s_id == &"speed")
				and x.strength < 1):
			sev -= x.strength * 0.1 - x.duration * 0.03
		if x.type.s_id == &"sopping":
			sev += x.strength * 0.21 + x.duration * 0.08
		if x.type.s_id == &"fire":
			sev += x.strength * 0.1 + x.duration * 0.07
		if x.type.s_id == &"poison":
			sev += x.strength * 0.12 + x.duration * 0.07
		if x.type.s_id == &"little":
			sev += x.strength * 0.1 + x.duration * 0.12
		if x.type.s_id == &"sleepy":
			sev += x.strength * 0.1 + x.duration * 0.3
	return sev * 0.06


static func suitable_for_buffing(spirit: String, enemy: BattleActor) -> bool:
	if enemy.character.armour == &"frankling_badge" and spirit == &"grandma_electric":
		return false
	return not spirit in UNSUITABLE_FOR_BUFFING


static func heheh_hahah(node: Node) -> void:
	for i in node.get_children():
		heheh_hahah(i)
	if not "text" in node:
		return
	node.text = "he".repeat(randi_range(1, 5)) + " " + "ha".repeat(randi_range(1, 5))
