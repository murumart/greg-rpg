class_name SlopeArea extends Area2D

enum Slopes {LEFT = -1, RIGHT = 1}

@export_enum("◄", "►") var slope: int
var bodies: Array[CharacterBody2D] = []


func _enter_tree() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	body_entered.connect(_body_entered)
	body_exited.connect(_body_exited)


func _physics_process(delta: float) -> void:
	for body in bodies:
		if not body.velocity:
			continue
		body.position.y += 60.0 * delta * signf(body.velocity.x) * (slope * 2 - 1)


func _body_entered(body: Node2D) -> void:
	if body is PlayerOverworld or body is OverworldCharacter:
		bodies.append(body)


func _body_exited(body: Node2D) -> void:
	bodies.erase(body)


