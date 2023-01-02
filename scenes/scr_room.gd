extends Node2D
class_name Room

@export_range(0, 32767) var id : int


func _init() -> void:
	DAT.set_data(DAT.CURRENT_ROOM, id)
