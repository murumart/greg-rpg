extends BattleEnemy

const UNSUITABLE_FOR_BUFFING := ["summon_vacuum", "smallshield"]
const USUAL := preload("res://sprites/characters/battle/grandma/spr_battle.png")
const USE_ITEM := preload("res://sprites/characters/battle/grandma/spr_use_item.png")
const USE_SPIRIT := preload("res://sprites/characters/battle/grandma/spr_use_spirit.png")
const ATTACK := preload("res://sprites/characters/battle/grandma/spr_attack.png")

const FINAL_TURNS := 16

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
@onready var background_transform: RemoteTransform2D = $AnimationSprite/BackgroundTransform

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
	var dbg_skip := false
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
		elif progress == FINAL_TURNS + 2 or dbg_skip:
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
			"greg, you little... man!",
			"it's never that easy!",
			"well, maybe it could be!",
			"maybe i could just send you back to your doorstep!",
			"but."
		]
		1: return [
			"i'm a bit more interested in you now.",
			"your flower-collection escapades were a huge boon!",
			"all those... ants!! ants who thought they were mighty!!",
			"the natural order of things returns, as it must...",
		]
		3: return [
			"dear, this fight right now...",
			"consider this your final challenge, greg.",
			"a final boss to surmount!",
			"after all, you are experienced enough...",
		]
		4:
			if pick_target().character.inventory.size() > 10:
				return [
					"by the way... all those items you've gathered...",
					"i've been doing some gathering of my own!",
					"so, it's a very fair battle!",
					"fairest than any other thus far, actually.",
				]
			return [
				"by the way... while you were slacking off...",
				"i was being vigilant and collecting items to use in battle!",
				"and i won't hold back... if i need to heal, i will!",
			]
		6: return [
			"when you arrived at my house, greg...",
			"how glad i am i seized the opportunity!",
			"you were not just another toy to throw aside...",
			"...once focus waned... you came back!!",
		]
		7: return [
			"no one has returned before, you know.",
			"i stopped believing they could!",
			"and when you did, i was momentarily terrified...",
			"if my projects were to become common knowledge...",
			"all those... rules... bindings!! i despise them!!",
			"this is my world!!",
		]
		8: return [
			"but you, greg... you found me again and lent your hand.",
			"the greatest cover-up in all of time and space...!",
			"and we're almost done here...",
		]
		10: return [
			"...almost done... because you are the last step.",
			"of course, i can't let you just go on your merry way...",
			"...after all the effort you went through...",
			"silencing you forever like them is not interesting.",
		]
		11: return [
			"why? dear, you are... very well attuned to this world!",
			"your spirit power rivals anyone elses!",
			"and that's why i can't let you go to waste.",
		]
		13: return [
			"someone like you should have much more to say...",
			"in what this world will end up like.",
			"but for now...",
			"you should hide. you should be hidden.",
		]
		14: return [
			"that is why, greg...",
			"that is why i will put you to sleep.",
			"and whenever you must intervene again...",
			"you'll always have been ready for it!",
			"you'll always be ready in stone!!",
		]
		FINAL_TURNS: return [
			"well, alright! stop the carnage!!",
		]
		FINAL_TURNS + 1: return [
			"greg, dear... you've proven yourself more than enough.",
			"and, i've had time to prepare my final move for now...",
			"the fabled...",
			"[color=#ff0]magical electric petrification beam!!!",
			"just one more turn for me, and then...",
			"i'll keep you safe, okay?",
		]
		FINAL_TURNS + 2: return [
			"greg!! take this!!",
			"[color=#ff0]petrify!!!",
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
