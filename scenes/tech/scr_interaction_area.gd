@tool
extends Area2D
class_name InteractionArea

# player interaction detector area

signal on_interact


func _ready() -> void:
	set_collision_layer_value(3, true)
	input_pickable = false
	modulate = Color.from_string("#e7a3ff", Color.WHITE)


func interacted() -> void:
	on_interact.emit()
