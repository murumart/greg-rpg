extends Node2D

enum States {STOP, MOVE}
var state : States = States.STOP

@onready var tilemap := $Blocks
@onready var noise : FastNoiseLite = $NoiseSprite.texture.noise

var speed := 60


func _ready() -> void:
	state = States.MOVE
	noise.seed = randi()


func _physics_process(delta: float) -> void:
	match state:
		States.MOVE:
			tilemap.position.y -= speed * delta
			noise.offset.y += (speed * delta) / 16.0
			process_tilemap()


func process_tilemap() -> void:
	var ypos := roundi(tilemap.position.y / 16.0)
	var path_noise_value := roundi(remap(noise.get_noise_1d(tilemap.position.y / 1600.0), -1, 1, -6, 6))
	print(path_noise_value)
	
	delete_offscreen_tiles(ypos)
	
	var rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x, 10)
		if (
				!(noise_value > -0.2 and noise_value < 0.2) and 
				!(absi(cell.x - path_noise_value) <= 2)
			) or (
				cell.x <= -5 or cell.x >= 4
			): rock_array.append(cell)
		
	tilemap.set_cells_terrain_connect(0, rock_array, 0, 0)


func delete_offscreen_tiles(ypos: int) -> void:
	for x in 12:
		var cell := Vector2i(x - 6, -ypos - 6)
		tilemap.set_cell(0, cell, -1)
