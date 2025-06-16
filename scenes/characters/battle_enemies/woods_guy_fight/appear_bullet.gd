extends Area2D

const APPEAR_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.tscn")
const AppearBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.gd")

var quick := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

static func create(quick_ := false) -> AppearBullet:
	var zb := APPEAR_BULLET.instantiate()
	zb.quick = quick_
	return zb


func _ready() -> void:
	if quick:
		animation_player.play("atk1")
		return
	animation_player.play("atk2")
