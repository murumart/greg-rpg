class_name ScreenEdgeBounceComponent extends Node

@export var target: Node2D
@export var bounce_rect: Rect2i = Rect2i(0, 0, 160, 120)
@export var speed: float = 60

var direction := Vector2()
@export_range(0, 360) var random_bounce_angle = 0


func _ready() -> void:
	direction.x = randf() * 2 - 1
	direction.y = randf() * 2 - 1
	direction = direction.normalized()


func _physics_process(delta: float) -> void:
	
	var future_pos := target.global_position + direction * speed * delta
	if future_pos.x >= bounce_rect.size.x:
		direction = direction.rotated(deg_to_rad(randf() * random_bounce_angle))
		direction.x *= -1
	elif future_pos.x <= bounce_rect.position.x:
		direction = direction.rotated(deg_to_rad(randf() * random_bounce_angle))
		direction.x *= -1
	elif future_pos.y >= bounce_rect.size.y:
		direction = direction.rotated(deg_to_rad(randf() * random_bounce_angle))
		direction.y *= -1
	elif future_pos.y <= bounce_rect.position.y:
		direction = direction.rotated(deg_to_rad(randf() * random_bounce_angle))
		direction.y *= -1
	else:
		target.global_position = future_pos
