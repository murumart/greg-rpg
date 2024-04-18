@tool
class_name SinAnimator extends Node

@export var property_name := &""
@export var target: Node2D
@export var speed := 1.0
@export var min_value := 0.0
@export var max_value := 1.0
@export var offset := 0.0
@export var random_offset := false


func _ready() -> void:
	assert(target)
	assert(property_name)
	if random_offset:
		offset = randf() * 5


func _physics_process(delta: float) -> void:
	if not target.visible:
		return
	var new_value := min_value + (sin(offset + Engine.get_physics_frames() * delta * speed) * max_value * 0.5)
	target.set_indexed(NodePath(property_name), new_value)
