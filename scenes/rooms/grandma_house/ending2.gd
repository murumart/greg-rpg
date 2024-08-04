extends Node2D

@onready var interior_tiles: TileMap = $"../InteriorTiles"
@onready var grandma := $"../InteriorTiles/Grandma"
@onready var greg_pos: Node2D = $GregPos
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera: Camera2D = $"../Greg/Camera"


func _ready() -> void:
	show()


func play() -> void:
	DAT.capture_player("cutscene")
	interior_tiles.set_layer_enabled(1, false)
	grandma.queue_free()
	greg.global_position = greg_pos.global_position
	greg.animate("walk_up")
	camera.global_position.y -= 20
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func():
		greg.animate("walk_up", true)
	)
	tw.tween_property(greg, "global_position:y", greg.global_position.y - 35, 3.0)
	tw.tween_callback(func():
		greg.animate("walk_up")
	)
