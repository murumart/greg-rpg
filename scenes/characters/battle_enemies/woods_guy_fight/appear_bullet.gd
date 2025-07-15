extends Area2D

const APPEAR_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.tscn")
const AppearBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.gd")

var quick := false
var speed := 1.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

static func create(quick_ := false, speed_ := 1.0) -> AppearBullet:
	var zb := APPEAR_BULLET.instantiate()
	zb.quick = quick_
	zb.speed = speed_
	return zb


func _ready() -> void:
	if quick:
		animation_player.play("atk1")
		return
	animation_player.speed_scale = speed
	animation_player.play("atk2")
