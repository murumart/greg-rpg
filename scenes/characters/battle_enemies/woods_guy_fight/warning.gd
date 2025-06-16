extends Node2D

const Warning = preload("res://scenes/characters/battle_enemies/woods_guy_fight/warning.gd")
const WARNING = preload("res://scenes/characters/battle_enemies/woods_guy_fight/warning.tscn")
const AppearBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.gd")

var rng: RandomNumberGenerator = null
var rect: Rect2

@onready var warning_sprite: Sprite2D = $Marker
@onready var animation_player: AnimationPlayer = $AnimationPlayer


static func create(rng_: RandomNumberGenerator, rect_: Rect2) -> Warning:
	var va := WARNING.instantiate() as Warning
	va.rng = rng_
	va.rect = rect_
	return va


func attack() -> void:
	warning_sprite.position = rect.position * 16 - Vector2(32, 32)
	warning_sprite.scale = rect.size
	animation_player.play("atk1")
	await animation_player.animation_finished
	for i in 20:
		var pos := rect.position * 16 + Vector2(
			rng.randf_range(8, rect.size.x * 16 - 8),
			rng.randf_range(8, rect.size.y * 16 - 8),
		)
		pos -= Vector2.ONE * 32
		var b := AppearBullet.create(true)
		add_sibling(b)
		b.position = pos
		await Math.timer(0.01)
	await Math.timer(0.1)
	queue_free()
