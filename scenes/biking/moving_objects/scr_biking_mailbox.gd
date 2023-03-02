extends BikingMovingObject

signal hit

const BOX_BASE_REG := Rect2(38, 41, 5, 4)
const BOX_WIDTH := 11

@onready var box := $Box

const EAT_SOUND := preload("res://sounds/paper/paper2.ogg")


func _ready() -> void:
	box.region_rect.position.x += (randi() % 3) * BOX_WIDTH
	box.self_modulate = Color(randf(), randf(), randf())


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		body.queue_free()
		hit.emit()
		SND.play_sound(EAT_SOUND, {"volume": -10})
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		$AnimationPlayer.play("yum")


func checkmark_animation() -> void:
	SOL.vfx("use_item", global_position + Vector2(0, -30), {"item_texture": preload("res://sprites/gui/spr_gui_checkmark.png"), "parent": self, "silent": true})

