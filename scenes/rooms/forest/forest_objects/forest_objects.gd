class_name ForestObjects extends RefCounted

enum {
	SCENE,
	SIZE,
	WEIGHT,
	LIMIT,
	FUNCTION, # runs before ready
	EVERY_X_ROOMS,
	MIN_ROOM,
	MAX_ROOM,
}
const DEFAULT_WEIGHT := 1000
const DEFAULT_SIZE := Vector2i(2, 2)

const DB = {
	&"grassy_clearing": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/grassy_clearing.tscn"),
		SIZE: Vector2i(4, 4),
		WEIGHT: 500,
	},
	&"grassy_clearing_2": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/grassy_2.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 1000,
	},
	&"grassy_clearing_3": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/grassy_3.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 2000,
	},
	&"waterhole": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/waterhole.tscn"),
		SIZE: Vector2i(4, 4),
		WEIGHT: 600,
	},
	&"lost_guy": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/lost_guy.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 1,
		LIMIT: 1
	},
	&"stump": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/stump.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 500,
	},
	&"bench": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/bench.tscn"),
		SIZE: Vector2i(3, 2),
		WEIGHT: 20,
	},
	&"sleepy_flower": {
		SCENE: preload("res://scenes/decor/scn_pickable_item.tscn"),
		SIZE: Vector2i(3, 2),
		WEIGHT: 60,
		LIMIT: 1,
		FUNCTION: &"_set_flower_sleepy"
	},
	&"funny_fungus": {
		SCENE: preload("res://scenes/decor/scn_pickable_item.tscn"),
		SIZE: Vector2i(3, 2),
		WEIGHT: 20,
		LIMIT: 1,
		FUNCTION: &"_set_fungus_funny"
	},
	&"stone_column": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/stone_column.tscn"),
		SIZE: Vector2i(2, 2),
		WEIGHT: 100,
		LIMIT: 3
	},
	&"pizzle_column": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/puzzle_column.tscn"),
		SIZE: Vector2i(2, 2),
		WEIGHT: 111,
		LIMIT: 1,
		FUNCTION: &"_connect_pizzle_finish",
	},
	&"saleskid": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/saleskid.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 800,
		LIMIT: 1
	},
	&"lime_head": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/lime_head.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 1,
	},
	&"pole": {
		SCENE: preload("res://scenes/decor/scn_utilitypole.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 70,
		FUNCTION: &"_connect_poles",
	},
	&"bird_hazard": {
		SCENE: preload("res://scenes/rooms/forest/forest_objects/bird_hazard.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 7000,
		LIMIT: 1,
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
