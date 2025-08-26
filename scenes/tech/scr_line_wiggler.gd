@tool
extends Line2D

@export var active_in_editor := true
@export var wiggle_range := Vector2(1, 1)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() and not active_in_editor: return
	for i in points.size():
		points[i] += Vector2(randf_range(-wiggle_range.x, wiggle_range.x), randf_range(-wiggle_range.y, wiggle_range.y)) * i * delta
