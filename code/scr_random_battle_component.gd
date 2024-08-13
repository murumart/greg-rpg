class_name RandomBattleComponent extends Node

@export var values: Array[KeyCurve] = []
@export var enemy_amount_by_level: Curve
@export var default_battle := BattleInfo.new()
@export_range(1, 6) var max_enemies := 4
@export var minimum_enemy_tries := 1
@export var inject_target: OverworldCharacter
@export var start_texts: Array[String] = []
@export var print_test_text := false
var _level := 0.0


func _ready() -> void:
	set_level(ResMan.get_character("greg").level)
	if inject_target:
		inject_target.battle_info = get_battle()
		#print("RBC: genned battle with level " + str(_level))
	if print_test_text and not DIR.standalone():
		for i in 100:
			_level = i * 0.01
			prints(i, gen_enemies())


func gen_enemies() -> Array[StringName]:
	var enemies: Array[StringName] = []
	enemies.append_array(default_battle.get_("enemies", []))
	var loopsraw := remap(_level, 0.0, 1.0, 1.0, max_enemies * 1.25)
	if enemy_amount_by_level:
		loopsraw = enemy_amount_by_level.sample_baked(_level)
	if roundi(loopsraw + 0.25) > roundi(loopsraw) and randf() < 0.5:
		loopsraw = ceili(loopsraw)
	var loops := maxi(roundi(loopsraw), minimum_enemy_tries)
	for i in loops:
		values.shuffle()
		for k in values:
			var curve := k.curve
			if curve.sample_baked(_level) >= randf():
				enemies.append(k.key)
				break
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


func set_level(nr_1_99: float) -> void:
	_level = remap(nr_1_99, 1, 99, 0.001, 1.0)


