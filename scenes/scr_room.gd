extends Node2D
class_name Room

@export var id : String = ""


func _init() -> void:
	self.add_to_group("save_me")


func _ready() -> void:
	DAT.set_data("current_room", name)


func _save_me() -> void:
	DAT.set_data("current_room", name)
