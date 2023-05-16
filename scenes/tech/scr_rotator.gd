@tool
extends Node2D

@export var enabled_in_editor := true
var affected_node : Node2D
@export var speed := 1.0


func _physics_process(delta: float) -> void:
	if not enabled_in_editor and Engine.is_editor_hint(): return
	affected_node = get_parent()
	if affected_node:
		affected_node.rotation_degrees = wrapf(affected_node.rotation_degrees + speed * delta, 0, 360.0)
