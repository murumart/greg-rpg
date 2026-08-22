@tool
class_name SinAnimator extends Node

@export var enabled := true
@export var property_name := &""
@export var target: Node
@export var speed := 1.0
@export var min_value := 0.0
@export var max_value := 1.0
@export var offset := 0.0
@export var random_offset := false
@export_exp_easing() var easing: float = 1.0


func _ready() -> void:
	assert(target)
	assert(property_name)
	if random_offset:
		offset = randf() * 5


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if not target.visible:
		return
	var sine := sin(offset + Engine.get_physics_frames() * delta * speed)
	var eased := 1.0 - 2.0 * ease(sine * 0.5 + 0.5, easing)
	var new_value := min_value + (eased * max_value * 0.5)
	target.set_indexed(NodePath(property_name), new_value)
