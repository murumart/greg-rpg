class_name GDUNGObjects

# size is centered on the object.
enum {SCENE, SIZE, BY_WALL, WEIGHT, ORDER_NR_MIN, MAX_PER_SUITE}

const DB := {
	&"bookshelf": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/bookshelf.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [100, 50, 25, 0],
		BY_WALL: true,
	},
	&"trashbag": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/trashbag.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [39, 12, 0],
	},
	&"statue": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/grandma_statue.tscn"),
		SIZE: Vector2i(3, 3),
		WEIGHT: 55,
	},
	&"pothole": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/pothole.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [12, 0],
	},
	&"catface1": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/catface.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 100,
		BY_WALL: true,
	},
	&"catface2": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/catface_big.tscn"),
		SIZE: Vector2i(2, 1),
		WEIGHT: 60,
		BY_WALL: true,
	},
	&"litterbox": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/litterbox.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [50, 20, 0],
	},
	&"drawer": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/desk_drawer.tscn"),
		SIZE: Vector2i(2, 1),
		WEIGHT: [80, 40, 10, 0],
		BY_WALL: true,
	},
	&"skeleton": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/skeleton.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 2,
		BY_WALL: true,
	},
	&"carpets": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/carpets.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 100,
		BY_WALL: true,
	},
	&"mayonnaise": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/mayonnaise.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [20, 2, 0],
	},
	&"mayonnaise_huge": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/mayonnaise_huge.tscn"),
		SIZE: Vector2i(2, 2),
		WEIGHT: [5, 5, 5, 0],
	},
	&"planet": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/planet.tscn"),
		SIZE: Vector2i(2, 2),
		WEIGHT: [0, 1, 1, 0],
		MAX_PER_SUITE: 1,
	},
	&"enemy": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cat_enemy.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: 110,
		ORDER_NR_MIN: 3,
		MAX_PER_SUITE: 1,
	},
	&"flower_1": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_1.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [75, 30, 1, 0],
	},
	&"flower_2": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_2.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [60, 30, 1, 0],
	},
	&"flower_3": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_3.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [75, 30, 1, 0],
	},
	&"flower_4": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_4.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [75, 30, 1, 0],
	},
	&"flower_5": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_5.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [75, 30, 1, 0],
	},
	&"flower_6": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/flower_6.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [75, 30, 1, 0],
	},
	&"dirtbag": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/dirtbag.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [60, 1, 0],
	},
	&"door": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/door.tscn"),
		SIZE: Vector2i(1, 2),
		WEIGHT: [12, 15, 40],
		BY_WALL: true,
	},
	&"shelf": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/shelf.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [100, 10, 0],
		BY_WALL: true,
	},
	&"shelf_2": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/shelf_hanging_flower.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [65, 10, 0],
		BY_WALL: true,
	},
	&"box_1": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cardboard_box_1.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [0, 30, 150],
	},
	&"box_2": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cardboard_box_2.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [0, 30, 150],
	},
	&"box_3": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cardboard_box_3.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [0, 15, 100],
	},
	&"box_4": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cardboard_box_4.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [0, 50, 180],
	},
	&"box_5": {
		SCENE: preload("res://scenes/rooms/grandma_house/gdung_objects/cardboard_box_5.tscn"),
		SIZE: Vector2i(1, 1),
		WEIGHT: [0, 50, 180],
	},

}


static func get_db_keys_by_weights() -> Dictionary:
	var dict := {}
	for key: StringName in DB:
		var inner: Dictionary = DB[key]
		var weight = inner.get(WEIGHT, 100)
		if weight is Array:
			weight = weight[clampi(DAT.get_data("gdung_floor", 0), 0, weight.size() - 1)]
		dict[key] = weight
	return dict
