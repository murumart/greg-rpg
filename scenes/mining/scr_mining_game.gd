class_name MiningGame extends Node2D


@onready var tiles := $Tiles
@onready var wall := $Wall
@onready var greg := $GregPlatform as PlatformerGreg

var hole_noise := FastNoiseLite.new()
var cave_noise := FastNoiseLite.new()
var cave_noise_thin := FastNoiseLite.new()
var main_tunnel_noise := FastNoiseLite.new()

# in tiles
var map_height := 200
var map_width := 20
var start_height := 15
const TSIZE := 8

# storing tiles
var rocks : Array[Vector2i] = []


func _ready() -> void:
	mapgen()


func _physics_process(delta: float) -> void:
	wall.global_position.y = greg.global_position.y


func mapgen() -> void:
	hole_noise.frequency = 0.04
	cave_noise.frequency = 0.04
	cave_noise_thin.frequency = 0.04
	main_tunnel_noise.frequency = 0.04
	hole_noise.seed = randi()
	cave_noise.seed = randi()
	cave_noise_thin.seed = randi()
	main_tunnel_noise.seed = randi()
	
	for yi in map_height:
		for xi in map_width:
			var y := yi + start_height
			var x := xi
			if not check_cave(x, y):
				rocks.append(Vector2i(x, y))
	
	tiles.set_cells_terrain_connect(0, rocks, 0, 0)


func check_cave(x: int, y: int) -> bool:
	if Math.inrange(cave_noise.get_noise_2d(x, y), 0.0, 0.25): return true
	if hole_noise.get_noise_2d(x, y) > 0.4: return true
	if Math.inrange(cave_noise_thin.get_noise_2d(x, y), 0.18, 0.25): return true
	if Math.inrange(main_tunnel_noise.get_noise_1d(y) * 8 + map_width * 0.5, x - 2, x + 2): return true
	return false


func update_map() -> void:
	tiles.set_cells_terrain_connect(0, rocks, 0, 0)






