extends Node

@export var collision_hide: CanvasItem


func _ready() -> void:
	SOL.set_dialogue_mode(1)
	collision_hide.hide()


func _exit_tree() -> void:
	SOL.set_dialogue_mode(0)
