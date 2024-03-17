class_name WRPair extends Resource

@export var id: StringName = &""
@export var weight: int = 1


func _init(_id: StringName, _weight: int = 1) -> void:
	id = _id
	weight = _weight
