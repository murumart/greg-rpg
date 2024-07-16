extends Node2D

@onready var grandma: OverworldCharacter = $"../Grandma/Grandma"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var tilemap: TileMap = $".."
@onready var gregpos: Vector2 = $Gregpos.global_position
@onready var grandmapos: Vector2 = $Grandmapos.global_position

func _ready() -> void:
	await get_tree().process_frame
	play()


func play() -> void:
	DAT.capture_player("cutscene")
	tilemap.set_layer_enabled(1, false)
	greg.global_position = gregpos
	grandma.global_position = grandmapos
	greg.animate("walk_up", false)
	await Math.timer(1.0)
	greg.global_position += Math.v2(12)

