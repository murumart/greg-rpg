@tool
extends Area2D
class_name InteractionArea

signal on_interact


func interacted() -> void:
	on_interact.emit()
