extends Node


func _ready() -> void:
	SOL.set_dialogue_mode(1)


func _exit_tree() -> void:
	SOL.set_dialogue_mode(0)
