class_name RandomBattleComponent extends Node

@export var values: Array[KeyCurve] = []
@export var default_battle := BattleInfo.new()
@export_range(1, 6) var max_enemies := 4
@export var inject_target: OverworldCharacter
var level := 0


func _ready() -> void:
	level = remap(DAT.get_character("greg").level, 1, 99, 0.001, 1.0)
	if inject_target:
		inject_target.battle_info = get_battle()


func gen_enemies() -> Array[String]:
	var enemies: Array[String] = default_battle.get_("enemies", []).duplicate()
	for i in ceili(level / 10.0) + 1:
		for k in values:
			var curve := k.curve as Curve
			if curve.sample(level) >= randf():
				enemies.append(str(k.key))
	enemies.shuffle()
	if enemies.size() > max_enemies:
		enemies.resize(max_enemies)
	return enemies


func get_battle() -> BattleInfo:
	var info := default_battle.duplicate(true)
	info.enemies = gen_enemies()
	return info

