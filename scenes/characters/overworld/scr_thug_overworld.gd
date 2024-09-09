extends OverworldCharacter

const TWERP_SYNONYMS := ["twerp", "twerp", "twerp", "nitwit", "nincompoop", "sucker", "moron", "nullity", "insect"]
const ENGAGE_SYNONYMS := ["engage", "engage", "engage", "feature", "be involved", "be engrossed", "lose",]
const TUSSLE_SYNONYMS := ["tussle", "tussle", "tussle", "struggle", "scuffle", "brawl", "scramble"]
@onready var random_battle_component: RandomBattleComponent = $RandomBattleComponent


func _ready() -> void:
	super._ready()
	if DAT.get_data("hunks_enabled", false):
		random_battle_component.values.clear()
		random_battle_component.values.append(KeyCurve.create_pair(&"hunk",
				preload("res://resources/res_curve_one.tres")))
		animated_sprite.sprite_frames = preload(
				"res://resources/characters/sfr_hunk_overworld.tres")
	SOL.dialogue_box.dial_concat("thug_catch_1", 0,
			[TWERP_SYNONYMS.pick_random(), ENGAGE_SYNONYMS.pick_random(),
			TUSSLE_SYNONYMS.pick_random()])
	random_battle_component.set_level(ResMan.get_character("greg").level)
	battle_info = random_battle_component.get_battle()


func interacted() -> void:
	super()
	if not RunFlags.thugs_battled_changed:
		DAT.incri("thugs_fought", battle_info.enemies.size())
		RunFlags.thugs_battled_changed = true


func _car_collision_response(car: CarOverworld) -> void:
	SOL.vfx("dustpuff", global_position, {"parent": get_parent()})
	SOL.vfx("bangspark", global_position, {"parent": get_parent()})
	SND.play_sound_2d(preload("res://sounds/attack_blunt.ogg"), global_position)
	var tw := create_tween()
	set_collision_mask_value(2, false)
	set_physics_process(false)
	var moveto := (car.global_position - car.target).normalized() * car.speed
	tw.tween_property(self, "global_position", moveto, 1.0)
	tw.tween_callback(queue_free)
