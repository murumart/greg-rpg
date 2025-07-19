extends Node2D

@onready var fish_scared: OverworldCharacter = $FishScared


func _ready() -> void:
	if "lakeside" in DAT.get_data("visited_rooms", []) or ResMan.get_character("greg").level > 19:
		fish_scared.queue_free()
