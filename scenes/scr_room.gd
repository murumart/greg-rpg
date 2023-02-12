extends Node2D
class_name Room


func _init() -> void:
	self.add_to_group("save_me")


func _ready() -> void:
	DAT.set_data("current_room", name.to_snake_case())


func _save_me() -> void:
	DAT.set_data("current_room", name.to_snake_case())



