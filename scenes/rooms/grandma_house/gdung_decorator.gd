class_name GDUNGDecorator extends Node

const OB_DB := GDUNGObjects.DB

@export var generator: GDUNGLayoutGenerator
@export var greg: PlayerOverworld
@onready var tilemap: TileMap = get_parent()
@export var objects_node: Node2D


func _ready() -> void:
	var path := generator.get_longest_path()
	greg.global_position = generator.suites[path[0]].get_rect().get_center() * 16.0
	_decorate_suites(path)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		await generator.ready
		tilemap.queue_redraw()
		_ready()


func _decorate_suites(path: PackedInt64Array) -> void:
	const DECORATION_TRIES := 5
	objects_node.get_children().map(func(a): a.queue_free())
	var to_decorate: Array[GDUNGSuite] = _get_suites_to_decorate(path)
	print(to_decorate)
	var keys_weights := GDUNGObjects.get_db_keys_by_weights()
	for _x in DECORATION_TRIES:
		for suite in to_decorate:
			var obkey := Math.weighted_random(keys_weights.keys(),
					keys_weights.values()) as StringName
			var object := OB_DB[obkey] as Dictionary
			var instance := object[GDUNGObjects.SCENE].instantiate() as Node2D
			var sut_pos := _get_suitable_position(suite,
					object.get(GDUNGObjects.SIZE),
					object.get(GDUNGObjects.BY_WALL, false))
			if sut_pos == Vector2i.ZERO:
				continue
			var position := (sut_pos * 16.0
					+ Vector2(object.get(GDUNGObjects.SIZE, Vector2.ONE)) * 8.0)
			print(position)
			objects_node.add_child.call_deferred(instance)
			instance.global_position = position
			suite.add_generated_object(obkey, object, instance)


func _get_suites_to_decorate(path: PackedInt64Array) -> Array[GDUNGSuite]:
	var to_decorate: Array[GDUNGSuite] = []
	for id in path:
		var suite := generator.suites[id]
		if not suite in to_decorate:
			to_decorate.append(suite)
		for side in 2:
			side += 2
			for x in suite.neighbors[side]:
				if not x in to_decorate:
					to_decorate.append(x)
				for side2 in 2:
					side2 += 2
					for y in x.neighbors[side2]:
						if not y in to_decorate:
							to_decorate.append(y)
	return to_decorate


func _get_suitable_position(suite: GDUNGSuite, size: Vector2i, hug_wall := false) -> Vector2i:
	var rect := suite.get_rect().grow_side(SIDE_TOP, -1)
	var possible_positions: Array[Vector2i] = []
	for y in range(1, rect.size.y, size.y):
		if y + size.y > rect.size.y:
			break
		if hug_wall and y > 1:
			break
		for x in range(1, rect.size.x - 1, size.x):
			if x + size.x > rect.size.x - 1:
				break
			var pos := Vector2i(x, y) + suite.get_position()
			var ob_rect := Rect2i(x, y, size.x, size.y)
			var ob_rect_glob := Rect2i(pos, size)
			var is_free := true
			for dict: Dictionary in suite.generated_objects:
				if (dict.get("rect") as Rect2i).intersects(ob_rect):
					is_free = false
					break
			for door_pos in suite.door_positions:
				if ob_rect_glob.grow(2).has_point(door_pos):
					is_free = false
					break
			if not is_free:
				continue
			possible_positions.append(pos)
	if possible_positions.is_empty():
		return Vector2i.ZERO
	return Math.determ_pick_random(possible_positions, generator.rng)


