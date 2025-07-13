extends Node2D

const ROSE_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.tscn")
const RoseBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.gd")

var direction := Vector2()
var reduction := 1.0


static func create() -> RoseBullet:
	return ROSE_BULLET.instantiate()


static func splort(amount: int, parent: Node, target: Vector2, flower_speed: float) -> void:
	for __ in amount:
		var rb := RoseBullet.create()
		parent.add_child(rb)
		rb.global_position = parent.global_position
		rb.direction = rb.global_position.direction_to(target)
		rb.direction = rb.direction.rotated(deg_to_rad(randf_range(-20, 20)))
		rb.direction *= flower_speed


func _physics_process(delta: float) -> void:
	if direction.length_squared() < 1:
		queue_free()
		return
	position += direction * delta
	direction *= reduction
