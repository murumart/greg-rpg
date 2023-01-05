extends Node2D
class_name Room

@export var id : String = ""


func _init() -> void:
	DAT.set_data("current_room", id)
	self.add_to_group("save_me")
