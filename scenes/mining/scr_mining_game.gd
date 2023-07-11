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


func _physics_process(_delta: float) -> void:
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
	
	for i in rocks:
		tiles.set_cell(0, i, 0, Vector2i(
			roundi(randf()), roundi(randf())))
	update_map()


func check_cave(x: int, y: int) -> bool:
	if Math.inrange(cave_noise.get_noise_2d(x, y), 0.0, 0.25): return true
	if hole_noise.get_noise_2d(x, y) > 0.4: return true
	if Math.inrange(cave_noise_thin.get_noise_2d(x, y), 0.18, 0.25): return true
	if Math.inrange(main_tunnel_noise.get_noise_1d(y) * 8 + map_width * 0.5, x - 2, x + 2): return true
	return false


func update_map() -> void:
	var time := Time.get_ticks_msec()
	
	print("finished map update: ", Time.get_ticks_msec() - time)





