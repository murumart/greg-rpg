extends Area2D
class_name InteractionArea
@tool

signal on_interact

@export var area_extents := Vector2i(16, 16):
	set(to):
		area_extents = to
		get_node("Shape").shape.size = to


func interacted() -> void:
	on_interact.emit()
