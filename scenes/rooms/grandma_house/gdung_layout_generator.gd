class_name GDUNGLayoutGenerator extends Node

signal greg_entered_suite(GDUNGSuiteScene)

const START_LAYOUT: PackedByteArray = [0, 0, 89, 89]

var suites: Array[GDUNGSuite] = []
var suites_by_rect := {}
var suite_layout := START_LAYOUT.duplicate()
var rng := RandomNumberGenerator.new()
var astar := AStar3D.new()

@onready var tilemap: TileMap = get_parent()


func _ready() -> void:

	generate()
	for x in START_LAYOUT[2]:
		for y in START_LAYOUT[3]:
			tilemap.set_cell(0, Vector2i(x, y), 1, Vector2i(randi() % 2, randi() % 2 + 1))


# DEBUG
#func _unhandled_key_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_text_delete"):
		#DAT.set_data("nr", randf())
		#generate()
		#ready.emit()


func generate() -> void:
	tilemap.queue_redraw()
	if DAT.get_data("gdung_gen_next_floor", false):
		DAT.incri("gdung_floor", 1)
	if DAT.get_data("gdung_floor", 0) >= 3:

		return
	rng.set_seed(DAT.get_data("nr", 0.0) * 1000 + DAT.get_data("gdung_floor", 0) * 2)
	tilemap.clear_layer(1)
	_begin_wall_definition() #
	_generate_suites_layout()
	_generate_suites_from_layout()
	_calculate_suite_neighbors()
	_make_suite_walls()
	#for s in suites:
		#for side in 2:
			#side += 2
			#for neighbor: GDUNGSuite in s.neighbors[side]:
				#tilemap.draw.connect(func():
					#tilemap.draw_line(
						#s.get_rect().get_center() * 16.0,
						#neighbor.get_rect().get_center() * 16.0,
						#Color(1.0 - side * 0.25, 0.0, side * 0.25),
						#1.0 + side
					#)
				#, CONNECT_ONE_SHOT)
	_create_wall_rectangle(
			Rect2i(START_LAYOUT[0], START_LAYOUT[1] - 1, START_LAYOUT[2], START_LAYOUT[3] + 1))
	_end_wall_definition() #


func _generate_suites_layout() -> void:
	var time := Time.get_ticks_msec()
	const SPLITS := 8
	const MIN_ROOM_SIZE := 10
	suite_layout = START_LAYOUT.duplicate()
	var last_split := VERTICAL
	for _s in SPLITS:
		assert(suite_layout.size() % 4 == 0, "suite_layout size is wrong")
		var layouts_in_here := int(suite_layout.size() * 0.25)
		var new_layout: PackedByteArray = []
		for h in layouts_in_here:
			var size := 0

			size = suite_layout[GDUNGSuite._XSIZE if last_split == VERTICAL else GDUNGSuite._YSIZE]
			if size < MIN_ROOM_SIZE:
				new_layout.append_array(suite_layout.slice(0, 4))
				suite_layout = GDUNGSuite.remove_4_from_array(suite_layout)
				continue
			var split_point := int(size * rng.randfn(0.5, 0.05))
			var split := (GDUNGSuite.split_array_horizontally(
					suite_layout, split_point) if last_split == VERTICAL else
					GDUNGSuite.split_array_vertically(suite_layout, split_point))
			new_layout.append_array(split)
			suite_layout = GDUNGSuite.remove_4_from_array(suite_layout)
		suite_layout = new_layout
		if last_split == VERTICAL:
			last_split = HORIZONTAL
		else:
			last_split = VERTICAL
	print("creating layout took ", Time.get_ticks_msec() - time, " ms")


func _generate_suites_from_layout() -> void:
	var time := Time.get_ticks_msec()
	assert(suite_layout.size() % 4 == 0, "layuout worng size")
	suites.clear()
	suites_by_rect.clear()
	var suite_count := int(suite_layout.size() * 0.25)
	astar.clear()
	for i in suite_count:
		var suite := GDUNGSuite.create_from_array(suite_layout)
		suite.id = i
		suites.append(suite)
		suites_by_rect[suite.get_rect()] = suite
		astar.add_point(i, Vector3(suite.get_position().x, suite.get_position().y, 0))
		#tilemap.draw.connect(func():
			#tilemap.draw_rect(globalise_rect(suite.get_rect()),
					#Color(randf(), randf(), randf(), 0.5).lightened(0.75), true)
		#, CONNECT_ONE_SHOT)
		suite_layout = GDUNGSuite.remove_4_from_array(suite_layout)
	print("creating suites took ", Time.get_ticks_msec() - time, " ms")


func _calculate_suite_neighbors() -> void:
	const MIN_DOOR_SPACE_REQUIRED := 6
	var time := Time.get_ticks_msec()
	var suite_count := suites_by_rect.size()
	var rect_keys := suites_by_rect.keys()
	for i in suite_count:
		var rect: Rect2i = rect_keys[i]
		var suite: GDUNGSuite = suites_by_rect[rect]
		# checking only to the right side and below
		for side in 2:
			side += 2
			var expansion := rect.grow_side(side, 1)
			for j in range(i, suite_count):
				var comparison_rect: Rect2i = rect_keys[j]
				if comparison_rect == rect:
					continue
				if expansion.intersects(comparison_rect):
					if (
							(side % 2 == 0
							and mini(
								rect.position.y + rect.size.y - comparison_rect.position.y,
								comparison_rect.position.y + comparison_rect.size.y
									- rect.position.y,
							) < MIN_DOOR_SPACE_REQUIRED)
							or
							(side % 2 != 0
							and mini(
								rect.position.x + rect.size.x - comparison_rect.position.x,
								comparison_rect.position.x + comparison_rect.size.x
									- rect.position.x,
							) < MIN_DOOR_SPACE_REQUIRED)
					):
						continue
					suite.add_neighbor(suites_by_rect[comparison_rect], side)
					astar.connect_points(suite.id, suites_by_rect[comparison_rect].id)
	print("neighbors took ", Time.get_ticks_msec() - time, " ms")


func _make_suite_walls() -> void:
	var time := Time.get_ticks_msec()
	get_tree().call_group("debug_buttons", "queue_free")
	var door_positions: Array[Vector2i] = []
	var handled: Array[GDUNGSuite] = []
	for suite: GDUNGSuite in suites:
		var rect := suite.get_rect()
		_create_some_wall(rect)
		#var button := Button.new() # DEBUG
		#button.text = str(suite).left(8)
		#button.global_position = suite.get_rect().position * 16
		#button.pressed.connect(func():
			#print(suite, ";\n", suite.neighbors,
					#"; ", suite.get_rect(), "; ", suite.get_rect().end,
					#"; ", suite.door_positions, "; ", suite.id,
					#";\n", astar.get_id_path(0, suite.id),
					#";\n", JSON.stringify(suite.generated_objects, "\t"))
		#)
		#button.add_to_group("debug_buttons")
		#add_child(button) # DEBUG
		if suite in handled:
			continue
		for neighbor: GDUNGSuite in suite.neighbors[SIDE_BOTTOM]:
			var minimal := neighbor if neighbor.get_x_size() < suite.get_x_size() else suite
			var door_x := minimal.get_rect().get_center().x
			door_x += rng.randi_range(-1, 1)
			while (door_x >= suite.get_rect().end.x - 1
					or door_x >= neighbor.get_rect().end.x - 1):
				door_x -= 1
			while (door_x <= suite.get_rect().position.x
					or door_x <= neighbor.get_rect().position.x):
				door_x += 1
			var door_position := Vector2i(
					door_x,
					neighbor.get_rect().position.y - 1)
			suite.door_positions.append(door_position)
			neighbor.door_positions.append(door_position)
			door_positions.append(door_position)
		for neighbor: GDUNGSuite in suite.neighbors[SIDE_RIGHT]:
			var minimal := neighbor if neighbor.get_y_size() < suite.get_y_size() else suite
			var door_y := minimal.get_rect().get_center().y
			door_y += rng.randi_range(-1, 1)
			while (door_y >= suite.get_rect().end.y - 1
					or door_y >= neighbor.get_rect().end.y - 1):
				door_y -= 1
			var door_position := Vector2i(
					neighbor.get_rect().position.x - 1,
					door_y)
			suite.door_positions.append(door_position)
			neighbor.door_positions.append(door_position)
			door_positions.append(door_position)
			door_positions.append(door_position + Vector2i(0, -1))
		var area := GDUNGSuiteScene.create(suite)
		add_child(area)
		area.greg_entered.connect(_greg_entered_scene)
		handled.append(suite)
	for pos in door_positions:
		walls.erase(pos)
	print("calculating walls took ", Time.get_ticks_msec() - time, " ms")


func get_longest_path() -> PackedInt64Array:
	var points_count := suites.size()
	var longest_path: PackedInt64Array = []
	for i in points_count - 1:
		for j in range(i + 1, points_count):
			var cur_path := astar.get_id_path(i, j)
			if cur_path.size() > longest_path.size():
				longest_path = cur_path
	if longest_path.is_empty():
		return suites.duplicate()
	return longest_path


var walls: Array[Vector2i] = []
func _begin_wall_definition() -> void:
	walls.clear()


func _create_wall_rectangle(rect: Rect2i) -> void:
	for x in rect.size.x:
		walls.append(Vector2i(rect.position.x + x, rect.position.y))
		walls.append(Vector2i(rect.position.x + x, rect.position.y + rect.size.y - 1))
	for y in rect.size.y - 2:
		walls.append(Vector2i(rect.position.x, rect.position.y + y + 1))
		walls.append(Vector2i(rect.position.x + rect.size.x - 1, rect.position.y + y + 1))


func _create_some_wall(rect: Rect2i) -> void:
	walls.append(Vector2i(rect.position.x + rect.size.x - 1, rect.position.y))
	for x in rect.size.x:
		walls.append(Vector2i(rect.position.x + x, rect.position.y + rect.size.y - 1))
	for y in rect.size.y - 2:
		walls.append(Vector2i(rect.position.x + rect.size.x - 1, rect.position.y + y + 1))


func _fill_some_wall(rect: Rect2i) -> void:
	for x in rect.size.x:
		for y in rect.size.y:
			walls.append(Vector2i(
					x + rect.position.x,
					y + rect.position.y))


func _end_wall_definition() -> void:
	tilemap.set_cells_terrain_connect(1, walls, 1, 3)
	walls.clear()


func globalise_rect(r: Rect2) -> Rect2:
	return Rect2(r.position * 16, r.size * 16)


func _greg_entered_scene(suite: GDUNGSuiteScene) -> void:
	greg_entered_suite.emit(suite)

