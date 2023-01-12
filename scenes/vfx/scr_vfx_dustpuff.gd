extends Node2D


func _ready() -> void:
	get_node("CPUParticles2D").emitting = true
