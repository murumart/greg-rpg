extends Node2D

const BIRD_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_bullet.tscn")
const ROSE_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.tscn")
const RoseBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.gd")

var direction := Vector2()
var reduction := 1.0


static func create() -> RoseBullet:
	return ROSE_BULLET.instantiate()


static func create_bird() -> RoseBullet:
	var rb := BIRD_BULLET.instantiate()
	return rb


func _physics_process(delta: float) -> void:
	if direction.length_squared() < 1:
		queue_free()
		return
	position += direction * delta
	direction *= reduction
