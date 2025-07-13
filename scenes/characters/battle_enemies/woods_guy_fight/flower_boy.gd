extends Node2D

const RoseBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.gd")
const FlowerBoy = preload("res://scenes/characters/battle_enemies/woods_guy_fight/flower_boy.gd")
const FLOWER_BOY = preload("res://scenes/characters/battle_enemies/woods_guy_fight/flower_boy.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $Sprite2D/Particles

@onready var throw: AudioStreamPlayer = $Throw

var delay := 0.0
var target: Node2D
var bullets := 1
var flower_speed := 60.0
var rng: RandomNumberGenerator = null


static func create(rng_: RandomNumberGenerator, target_: Node2D, bullets_: int, flowerspeed := 60.0) -> FlowerBoy:
	var fb: FlowerBoy = FLOWER_BOY.instantiate()
	fb.rng = rng_
	fb.target = target_
	fb.bullets = bullets_
	fb.flower_speed = flowerspeed
	fb.delay = 1.0
	return fb


func _physics_process(delta: float) -> void:
	position.y += delta * 45
	position.x += sin(position.y * 0.15)
	delay -= delta
	if delay <= 0.5:
		sprite.region_rect.position.y = 0
		particles.texture.region.position.y = 0
	if delay <= 0:
		delay = 1
		sprite.region_rect.position.y = 16
		particles.texture.region.position.y = 16
		throw.play()
		if not is_instance_valid(target):
			print("no target")
			return
		RoseBullet.splort(bullets, get_parent(), target.global_position, flower_speed)
