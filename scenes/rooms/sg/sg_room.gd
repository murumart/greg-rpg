extends Node

@export var collision_hide: CanvasItem


func _ready() -> void:
	# window resolution change is in camera node.
	collision_hide.hide()


func _exit_tree() -> void:
	pass
