extends Resource
class_name BattleInfo

@export var enemies : Array[int] = []
@export var background := "bikeghost"
@export var music := ""
@export var party : Array[int] = [0]


func set_enemies(x: Array) -> BattleInfo:
	enemies = x
	return self


func get_(x: StringName, default) -> Variant:
	if get(x):
		return get(x)
	else:
		return default
