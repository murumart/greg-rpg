class_name ForestObjects extends RefCounted

enum {SCENE, SIZE, WEIGHT, LIMIT, FUNCTION}
const DEFAULT_WEIGHT := 100.0
const DEFAULT_SIZE := Vector2i(2, 2)

const DB = {
	&"grassy_clearing": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/grassy_clearing.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 100.0,
	},
	&"lost_guy": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/lost_guy.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 2.0,
		LIMIT: 1
	},
	&"stump": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/stump.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 50.0,
	},
	&"bench": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/bench.tscn"),
		SIZE: Vector2i(3, 2),
		WEIGHT: 3.0,
	},
	&"sleepy_flower": {
		SCENE: preload("res://scenes/decor/scn_pickable_item.tscn"),
		SIZE: Vector2i(3, 2),
		WEIGHT: 7.7,
		LIMIT: 1,
		FUNCTION: &"_set_flower_sleepy"
	},
	&"stone_column": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/stone_column.tscn"),
		SIZE: Vector2i(2, 2),
		WEIGHT: 10.0,
		LIMIT: 3
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

