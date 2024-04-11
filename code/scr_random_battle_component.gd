class_name RandomBattleComponent extends Node

@export var values: Array[KeyCurve] = []
@export var default_battle := BattleInfo.new()
@export_range(1, 6) var max_enemies := 4
@export var minimum_enemy_tries := 1
@export var inject_target: OverworldCharacter
@export var start_texts: Array[String] = []
var level := 0.0


func _ready() -> void:
	set_level()
	if inject_target:
		inject_target.battle_info = get_battle()


func gen_enemies() -> Array[StringName]:
	set_level()
	var enemies: Array[StringName] = []
	enemies.append_array(default_battle.get_("enemies", []).duplicate())
	var loops := maxi(ceili(level / 10.0), minimum_enemy_tries)
	for i in loops:
		values.shuffle()
		for k in values:
			var curve := k.curve as Curve
			if curve.sample_baked(level) >= randf():
				enemies.append(str(k.key))
	enemies.shuffle()
	if enemies.size() > max_enemies:
		enemies.resize(max_enemies)
	# last failsafe
	if enemies.is_empty():
		printerr("enemy generation made empty array")
		enemies.append(values.pick_random().key)
	return enemies


func get_battle() -> BattleInfo:
	var info := default_battle.duplicate(true) as BattleInfo
	info.enemies = gen_enemies()
	if start_texts.size():
		info.start_text = start_texts.pick_random()
	return info


func set_level() -> void:
	level = remap(ResMan.get_character("greg").level, 1, 99, 0.001, 1.0)


