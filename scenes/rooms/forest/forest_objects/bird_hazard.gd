extends Node2D

const BirdBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_bullet.gd")

@onready var player_ara: Area2D = $PlayerAra
@onready var timer: Timer = $Timer

var player: PlayerOverworld


func _ready() -> void:
	player_ara.body_entered.connect(func(p: PlayerOverworld) -> void:
		player = p
	)
	player_ara.body_exited.connect(func(_p: PlayerOverworld) -> void:
		player = null
	)
	timer.wait_time = remap(DAT.get_data("forest_depth", 1), 1, 99, 0.5, 4.0)
	$PlayerAra/CollisionShape2D.shape.radius = remap(DAT.get_data("forest_depth", 1), 1, 99, 90, 400)
	timer.timeout.connect(_timer)
	timer.start()


func _timer() -> void:
	if is_instance_valid(player):
		var bb := BirdBullet.create_bird()
		bb.direction = global_position.direction_to(player.global_position + Vector2.UP * 8) * 80
		add_sibling(bb)
		bb.global_position = global_position
