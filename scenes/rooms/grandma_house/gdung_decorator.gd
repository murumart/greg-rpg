class_name GDUNGDecorator extends Node

const OB_DB := GDUNGObjects.DB
const EXIT_PORTAL := preload(
		"res://scenes/rooms/grandma_house/gdung_objects/exit_portal.tscn")
const HEALER := preload("res://scenes/rooms/grandma_house/gdung_objects/gdung_healer.tscn")

@export var generator: GDUNGLayoutGenerator
@export var greg: PlayerOverworld
@onready var tilemap: TilemapLayerParent = get_parent()
@export var objects_node: Node2D
@export var path_line: Line2D
@export var canvas_modulate: CanvasModulate
var _decor_id := -1
var path := PackedInt64Array()


func _ready() -> void:
	_decor_id = -1
	path = generator.get_longest_path()
	if path.is_empty():
		return
	_decorate_suites()
	_draw_path()
	canvas_modulate.color = canvas_modulate.color.darkened(0.1
			* DAT.get_data("gdung_floor", 0))
	await Math.timer(1.0)
	if is_instance_valid(SND.current_song_player):
		SND.current_song_player.pitch_scale = (
				remap(DAT.get_data("gdung_floor", 0), 0, 2, 1.0, 0.94))


func apply_spawn_point(greg_2: PlayerOverworld) -> void:
	if path.is_empty():
		return
	if (LTS.gate_id == &"" or DAT.get_data("gdung_gen_next_floor", false)
			or LTS.gate_id == &"gdung-house"):
		DAT.set_data("gdung_gen_next_floor", false)
		greg_2.global_position = generator.suites[path[0]].get_rect().get_center() * 16.0


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		await generator.ready
		tilemap.queue_redraw()
		_ready()


func _decorate_suites() -> void:
	var time := Time.get_ticks_msec()
	const DECORATION_TRIES := 5
	objects_node.get_children().map(func(a): a.queue_free())
	var to_decorate: Array[GDUNGSuite] = _get_suites_to_decorate()
	var keys_weights := GDUNGObjects.get_db_keys_by_weights()
	for _x in DECORATION_TRIES:
		for i in to_decorate.size():
			var suite: GDUNGSuite = to_decorate[i]
			_decorate_suite(suite, keys_weights, i)
	var last_suite: GDUNGSuite = generator.suites[path[path.size() - 1]]
	var second_suite: GDUNGSuite = generator.suites[path[1]]
	var exit := EXIT_PORTAL.instantiate()
	var healer := HEALER.instantiate()
	objects_node.add_child.call_deferred(exit)
	objects_node.add_child.call_deferred(healer)
	exit.global_position = last_suite.get_rect().get_center() * 16.0
	healer.global_position = second_suite.get_rect().get_center() * 16.0
	print("decorating ", to_decorate.size(), " suites took ", Time.get_ticks_msec() - time)


func _decorate_suite(
		suite: GDUNGSuite,
		keys_weights: Dictionary,
		approximate_order: int) -> bool:
	_decor_id += 1
	var _tries := 0
	var obkey := StringName()
	var object := {}
	var sut_pos := Vector2i.ZERO
	while _tries < 8:
		_tries += 1
		obkey = Math.weighted_random(keys_weights.keys(),
				keys_weights.values(), generator.rng) as StringName
		object = OB_DB[obkey] as Dictionary
		if object.get(GDUNGObjects.ORDER_NR_MIN, 0) > approximate_order:
			continue
		if object.get(GDUNGObjects.MAX_PER_SUITE, 9999) <= suite.count_objects(obkey):
			continue
		sut_pos = _get_suitable_position(suite,
				object.get(GDUNGObjects.SIZE),
				object.get(GDUNGObjects.BY_WALL, false))
		if sut_pos == Vector2i.ZERO:
			continue
		break
	if sut_pos == Vector2i.ZERO:
		return false
	var position := sut_pos * 16.0
	return _place_object(obkey, object, position, suite)


func _place_object(
		obkey: StringName,
		object: Dictionary,
		position: Vector2,
		suite: GDUNGSuite) -> bool:
	var instance := object[GDUNGObjects.SCENE].instantiate() as Node2D
	objects_node.add_child.call_deferred(instance)
	instance.global_position = position
	suite.add_generated_object(obkey, object, instance, _decor_id)
	instance.set_meta("gdung_suite", suite)
	instance.set_meta("gdung_greg", greg)
	return true


func _get_suites_to_decorate() -> Array[GDUNGSuite]:
	var to_decorate: Array[GDUNGSuite] = []
	for id in path:
		var suite := generator.suites[id]
		if not suite in to_decorate:
			to_decorate.append(suite)
		for neighbors in suite.neighbors.values():
			for neighbor: GDUNGSuite in neighbors:
				if neighbor in to_decorate:
					continue
				to_decorate.append(neighbor)
	if not path.is_empty():
		to_decorate.erase(generator.suites[path[path.size() - 1]])
		to_decorate.erase(generator.suites[path[0]])
		to_decorate.erase(generator.suites[path[1]])
	return to_decorate


func _get_suitable_position(suite: GDUNGSuite, size: Vector2i, hug_wall := false) -> Vector2i:
	var rect := suite.get_rect().grow_side(SIDE_TOP, -1)
	var possible_positions: Array[Vector2i] = []
	for y in range(1, rect.size.y, size.y):
		if (y + size.y > rect.size.y) or (hug_wall and y > 1):
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


func _draw_path() -> void:
	path_line.clear_points()
	for id in path:
		path_line.add_point(generator.suites[id].get_rect().get_center() * 16.0)
