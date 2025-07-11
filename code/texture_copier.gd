@tool
class_name SpriteFrameToParticleTextureCopier extends Node

@export var from: AnimatedSprite2D
@export var to: GPUParticles2D


func _process(_delta: float) -> void:
	if to.visible and from.visible:
		to.texture = from.sprite_frames.get_frame_texture(from.animation, from.frame)
