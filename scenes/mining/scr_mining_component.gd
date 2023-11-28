class_name MiningComponent extends Node2D

const TileDefinitions := preload("res://scenes/mining/resources/scr_tile_definitions.gd")

@export var target : PlatformerGreg
@export var display : Panel
@export var tilemap : TileMap

const TSIZE := 8

const UNMINEABLE := [-1, 2]

var input : Vector2 = Vector2()


func _ready() -> void:
	assert(target, "no target available")
	assert(tilemap, "no tilemap available")


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
	print(get_tile(pos))
	tilemap.erase_cell(0, pos)
	target.atree.set("parameters/hitshot/request", PlatformerGreg.FIRE)


func tpos() -> Vector2:
	return Vector2(Vector2i(target.position / TSIZE)) * TSIZE


func get_tile(where: Vector2) -> int:
	var tiledata := tilemap.get_cell_tile_data(0, Vector2i(where))
	return tiledata.terrain if tiledata else -1


func manage_display(target_pos : Vector2, _direction : int, delta : float) -> void:
	#display.position = target_pos
	display.position = display.position.lerp(target_pos, delta * 24)
	display.position -= Math.v2(0.5)
	display.size = Math.v2(TSIZE + 2)
	

