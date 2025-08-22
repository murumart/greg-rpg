@tool
class_name Rotator extends Node2D

@export var enabled_in_editor := false
var affected_node: Node2D
@export var speed := 1.0
@export var disable_all: bool = false:
	set(to):
		get_tree().get_nodes_in_group("__rotators__").map(func(a): a.enabled_in_editor = not a.enabled_in_editor)
@export var child_mode := false


func _init() -> void:
	add_to_group("__rotators__")


func _physics_process(delta: float) -> void:
	if not enabled_in_editor and Engine.is_editor_hint(): return
	if child_mode:
		affected_node = self
	else:
		affected_node = get_parent()
	if affected_node:
		affected_node.rotation_degrees = wrapf(affected_node.rotation_degrees + speed * delta, 0, 360.0)
