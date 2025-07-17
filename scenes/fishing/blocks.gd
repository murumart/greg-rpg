extends Node2D

const FG = preload("res://scenes/fishing/scr_fishing_minigame.gd")

signal fish_spawn_request(pos: Vector2)

@onready var background: TileMapLayer = $background
@onready var foreground: TileMapLayer = $foreground

@export_range(0, 1) var foreground_source := 0
@export_range(0, 1) var background_source := 1
@export var noise_sprite: Sprite2D
@onready var noise: FastNoiseLite = (noise_sprite.texture as NoiseTexture2D).noise

var state: FG.States = FG.States.STOP
var speed := 60.0
var processed_ypos := 1


func _ready() -> void:
	noise.seed = randi()


func _physics_process(delta: float) -> void:
	match state:
		FG.States.MOVE:
			position.y -= speed * delta
			noise.offset.y += (speed * delta) / 16.0
			process_tilemap()


func process_tilemap() -> void:
	# the tilemap actually continuously
	var ypos := roundi(position.y * 0.0625)
	if ypos == processed_ypos:
		return

	var path_noise_value := roundi((remap(
			noise.get_noise_1d(position.y * 0.000125), -1, 1, -6, 6)
			+ remap(noise.get_noise_1d((position.y + 1) * 0.000125),
			-1, 1, -6, 6)) * 0.5)

	# this might optimise things. i hope
	delete_offscreen_tiles(ypos)

	var rock_array := []
	# tilemap width is 12
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x, 10)
		# random caves
		if (not (noise_value > -0.2 and noise_value < 0.2) and
			not (absi(cell.x - path_noise_value) <= 2) and
			randf() <= 0.95
		) or (cell.x <= -5 or cell.x >= 4):
			rock_array.append(cell)
		else: #spawn fish
			fish_spawn_request.emit(to_global(foreground.map_to_local(cell)))
	# background
	var bg_rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x + 384, 10)
		if (noise_value > 0 and randf() <= 0.95) or (cell.x <= -5 or cell.x >= 4):
			bg_rock_array.append(cell)

	_set_cells(rock_array, bg_rock_array)

	processed_ypos = ypos


# the most process intensive part of process_tilemap
func _set_cells(rock_array: Array, bg_rock_array: Array) -> void:
	if not bool(OPT.get_opt("less_fancy_graphics")):
		foreground.set_cells_terrain_connect(rock_array, 0, foreground_source)
		background.set_cells_terrain_connect(bg_rock_array, 0, background_source)
		return
	# lower graphics
	for pos in rock_array:
		foreground.set_cell(pos, foreground_source, Vector2i(13, 16))
	for pos in bg_rock_array:
		background.set_cell(pos, background_source, Vector2i(13, 16))


func delete_offscreen_tiles(ypos: int) -> void:
	for x in 12:
		var cell := Vector2i(x - 6, -ypos - 6)
		foreground.erase_cell(cell)
		background.erase_cell(cell)
