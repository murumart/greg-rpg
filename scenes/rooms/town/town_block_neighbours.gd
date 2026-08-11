extends Node2D

@onready var fish_scared: OverworldCharacter = $FishScared


func _ready() -> void:
	if DAT.visited_room("lakeside"):
		fish_scared.queue_free()
