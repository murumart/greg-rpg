extends Node2D

@onready var fish_scared: OverworldCharacter = $FishScared


func _ready() -> void:
	if "lakeside" in DAT.get_data("visited_rooms", []):
		fish_scared.queue_free()
