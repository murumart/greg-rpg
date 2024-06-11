@tool
extends Line2D

@export var follow_what: Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(follow_what) or points.size() < 2:
		return
	points[1] = to_local(follow_what.global_position)
