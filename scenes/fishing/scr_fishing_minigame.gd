extends Node2D

enum States {STOP, MOVE}
var state : States = States.STOP

const FISH_LOAD := preload("res://scenes/fishing/scn_fish.tscn")

@onready var tilemap := $Blocks
var processed_ypos := 1
@onready var noise : FastNoiseLite = $NoiseSprite.texture.noise
@onready var hook := $Hook
@onready var hook_animator := $Hook/HookAnimator
@onready var line_drawer := $LineDrawer
var hook_positions := [Vector2(0,-60)]

@onready var fish_parent := $FishParent

var speed := 60
var depth := 0.0

@export var depth_fish_increase_curve : Curve


func _ready() -> void:
	state = States.MOVE
	noise.seed = randi()
	$Hook/HookCollision.body_entered.connect(_on_hook_collision)
	$Hook/HookCollision.area_entered.connect(_on_hook_collision)
	line_drawer.draw.connect(_on_line_draw)


func _physics_process(delta: float) -> void:
	match state:
		States.MOVE:
			hook_movement(delta)
			
			tilemap.position.y -= speed * delta
			noise.offset.y += (speed * delta) / 16.0
			depth += delta * speed
			$DepthLabel.text = str("depth: %s m" % snappedi(depth / 100.0, 0))
			process_tilemap()


func hook_movement(delta: float) -> void:
	for pos in hook_positions:
		var i := hook_positions.find(pos)
		pos.y -= speed * delta
		pos.x = move_toward(pos.x, hook.global_position.x, delta * randf_range(2, 4))
		if pos.y < -66:
			hook_positions.remove_at(i)
		else:
			hook_positions[i] = pos
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	hook.global_position += input * speed * 1 * delta
	hook.global_position.y = clampf(hook.global_position.y, -60, 60)
	$Hook/Look.rotation_degrees = move_toward($Hook/Look.rotation_degrees, input.x * 30, speed * delta * (2 * int(not bool(input.x) or signf($Hook/Look.rotation_degrees) != signf(input.x))) + 1)
	if Engine.get_physics_frames() % 4 == 0:
		hook_positions.append(hook.global_position)
	line_drawer.queue_redraw()


func _on_hook_collision(node: Node2D) -> void:
	if node is TileMap:
		return
		#get_tree().reload_current_scene()
		state = States.STOP
	elif node is Area2D and node.get_parent() is FishingFish:
		node.get_parent().queue_free()
	hook_animator.play("hit")


func _on_line_draw() -> void:
	for i in hook_positions.size():
		var pos : Vector2 = hook_positions[i]
		line_drawer.draw_line(
			Vector2(0, -99) if i <= 0 else hook_positions[i - 1],
			pos if i < hook_positions.size() - 1 else hook.global_position,
			Color.BLACK,
			1.0
		)


func process_tilemap() -> void:
	var ypos := roundi(tilemap.position.y / 16.0)
	if ypos == processed_ypos: return
	var path_noise_value := roundi((remap(noise.get_noise_1d(tilemap.position.y / 8000.0), -1, 1, -6, 6) + remap(noise.get_noise_1d((tilemap.position.y + 1) / 8000.0), -1, 1, -6, 6)) / 2.0)
	
	delete_offscreen_tiles(ypos)
	
	var rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x, 10)
		if (
				!(noise_value > -0.2 and noise_value < 0.2) and 
				!(absi(cell.x - path_noise_value) <= 2) and 
				randf() <= 0.95
			) or (
				cell.x <= -5 or cell.x >= 4
			): rock_array.append(cell)
	
	var bg_rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x + 384, 10)
		if (noise_value > 0 and randf() <= 0.95) or (cell.x <= -5 or cell.x >= 4):
			bg_rock_array.append(cell)
	
	tilemap.set_cells_terrain_connect(1, rock_array, 0, 0)
	tilemap.set_cells_terrain_connect(0, bg_rock_array, 0, 1)
	
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 4)
		if not tilemap.get_cell_tile_data(1, cell):
			if randf() < depth_fish_increase_curve.sample(depth / 10_000.0) / 2.0: spawn_fish(tilemap.to_global(tilemap.map_to_local(cell)))
	
	processed_ypos = ypos
	


func spawn_fish(coords : Vector2) -> void:
	var fish := FISH_LOAD.instantiate()
	fish.global_position = coords
	fish.depth = roundi(depth / 100.0)
	fish_parent.add_child(fish)


func delete_offscreen_tiles(ypos: int) -> void:
	for x in 12:
		var cell := Vector2i(x - 6, -ypos - 6)
		tilemap.erase_cell(0, cell)
