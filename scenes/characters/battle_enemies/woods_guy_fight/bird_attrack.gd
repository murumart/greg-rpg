extends Node2D

const BIRD_ATTRACK = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_attrack.tscn")
const BirdBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_bullet.gd")
const BirdAttrack = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_attrack.gd")

var time := 0.0
var rng: RandomNumberGenerator = null
var delay := 0.8


static func create(rng_: RandomNumberGenerator, delay_: float) -> BirdAttrack:
	var ba := BIRD_ATTRACK.instantiate()
	ba.rng = rng_
	ba.delay = delay_
	return ba


func _physics_process(delta: float) -> void:
	time += delta
	if time > 1:
		time = delay
		var pos := Vector2(rng.randf_range(-200, 200), rng.randf_range(80, 120))
		var bird := BirdBullet.create_bird()
		bird.direction = pos.direction_to(global_position) * rng.randf_range(50, 80)
		add_sibling(bird)
		bird.global_position = pos
