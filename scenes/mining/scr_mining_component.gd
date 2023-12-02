class_name MiningComponent extends Node2D

const TileDefinitions := preload("res://scenes/mining/resources/scr_tile_definitions.gd")

@export var target : PlatformerGreg
@export var display : Panel
@export var tilemap : TileMap

const TSIZE := 8

const UNMINEABLE := [-1, 2, 3, 4]

var input : Vector2 = Vector2()


func _ready() -> void:
	assert(target, "no target available")
	assert(tilemap, "no tilemap available")


func _input(event: InputEvent) -> void:
	# DEBUG
	if event is InputEventMouseButton and event.is_pressed():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var pos := tilemap.local_to_map(tilemap.to_local(get_global_mouse_position()))
		#print(tilemap.local_to_map(tilemap.to_local(get_global_mouse_position())))
		#tilemap.set_cell(0, pos, 0, Vector2i(0, 3))
		print(tilemap.get_cell_source_id(0, pos))


func _physics_process(delta: float) -> void:
	if target.last_input.x: input = target.last_input
	var direction := 0
	if input.x > 0: direction = 1
	elif input.x < 0: direction = -1
	
	var target_pos := Vector2()
	target_pos = tpos()
	if Input.get_axis("move_up", "move_down"):
		if Input.is_action_pressed("move_down"):
			target_pos.y += TSIZE
		elif Input.is_action_pressed("move_up"):
			target_pos.y -= 2 * TSIZE
		if Input.get_axis("move_left", "move_right"):
			target_pos.x += TSIZE * direction
	else:
		target_pos.x += TSIZE * direction
	# catch higher tiles if no lower tiles exist
	if not get_tile(target_pos / 8 - Vector2(0, 1)
		) in UNMINEABLE and get_tile(target_pos / 8) in UNMINEABLE:
		target_pos.y -= TSIZE
	
	if display:
		manage_display(target_pos, direction, delta)
	if Input.is_action_just_pressed("ui_cancel"):
		tile_action(target_pos / TSIZE)


func tile_action(pos: Vector2) -> void:
	var tile := get_tile(pos)
	var def := get_tile_definition(tile)
	if not tile in UNMINEABLE:
		tilemap.set_cells_terrain_connect(0, [Vector2i(pos)], 0, -1)
	target.atree.set("parameters/hitshot/request", PlatformerGreg.FIRE)


func tpos() -> Vector2:
	return Vector2(Vector2i(target.position / TSIZE)) * TSIZE


func get_tile(where: Vector2) -> int:
	return tilemap.get_cell_source_id(0, Vector2i(where))


func get_tile_definition(id: int) -> TileDefinitions.Tile:
	return TileDefinitions.tile(id)


func manage_display(target_pos : Vector2, _direction : int, delta : float) -> void:
	#display.position = target_pos
	display.position = display.position.lerp(target_pos, delta * 24)
	display.position -= Math.v2(0.5)
	display.size = Math.v2(TSIZE + 2)
	

