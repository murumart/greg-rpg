@tool
extends Area2D
class_name InteractionArea

# player interaction detector area

signal interacted


func _ready() -> void:
	set_collision_layer_value(3, true)
	input_pickable = false
	modulate = Color.from_string("#e7a3ff", Color.WHITE)


func on_interaction() -> void:
	interacted.emit()
