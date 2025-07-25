extends Node2D

@onready var door_area := $DoorArea


func _ready() -> void:
	door_area.knocked.connect(func() -> void:
		if not &"key_youthcentre" in ResMan.get_character("greg").inventory:
			door_area.destination = ""
	)
