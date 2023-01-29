extends Resource
class_name BattleInfo

@export var enemies : Array[int] = []
@export var background := "bikeghost"
@export var music := ""
@export var party : Array[int] = [0]


func set_enemies(x: Array[int]) -> BattleInfo:
	enemies = x
	return self


func set_background(x: String) -> BattleInfo:
	background = x
	return self


func set_music(x: String) -> BattleInfo:
	music = x
	return self


func set_party(x: Array[int]) -> BattleInfo:
	party = x
	return self


func get_(x: StringName, default) -> Variant:
	if get(x):
		return get(x)
	else:
		return default
