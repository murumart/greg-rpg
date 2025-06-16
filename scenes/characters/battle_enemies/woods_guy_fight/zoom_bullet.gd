extends Area2D

signal done

const ZOOM_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/zoom_bullet.tscn")
const ZoomBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/zoom_bullet.gd")

@onready var sprite: Sprite2D = $Sprite2D
var target: Vector2
var duration: float


static func create(target_: Vector2, duration_: float) -> ZoomBullet:
	var zb := ZOOM_BULLET.instantiate()
	zb.target = target_
	zb.duration = duration_

	return zb


func _ready() -> void:
	sprite.modulate = Color.TRANSPARENT


func attack() -> void:
	SND.play_sound(preload("res://sounds/teleport.ogg"))
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "scale", Vector2(1.2, 0.8), duration * 0.1)
	tw.parallel().tween_property(sprite, "modulate", Color.WHITE, duration * 0.1)
	tw.tween_callback(SND.play_sound.bind({"volume": 16}).bind(preload("res://sounds/chemistry/evaporate.ogg")))
	tw.tween_property(self, "global_position", target, duration)
	tw.parallel().tween_property(sprite, "scale", Vector2(1.2, 0.8), duration * 0.1)
	tw.tween_property(sprite, "scale", Vector2(0.8, 1.2), duration * 0.1)
	tw.tween_property(sprite, "scale", Vector2.ONE, duration * 0.1)
	tw.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, duration * 0.1)
	await tw.finished
	queue_free()
