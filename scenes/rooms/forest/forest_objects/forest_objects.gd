class_name ForestObjects extends RefCounted

enum {SCENE, SIZE, WEIGHT}
const DEFAULT_WEIGHT := 10.0
const DEFAULT_SIZE := Vector2i(2, 2)

const DB = {
	&"grassy_clearing": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/grassy_clearing.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 10.0,
	},
}


static func get_db_keys_by_weights() -> Dictionary:
	var dict := {}
	for key: StringName in DB:
		var inner: Dictionary = DB[key]
		dict[key] = inner.get(WEIGHT, DEFAULT_WEIGHT)
	return dict


static func get_object(key: StringName) -> Dictionary:
	return DB[key]
