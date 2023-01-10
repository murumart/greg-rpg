extends Node2D


func _ready() -> void:
	print(global_position)
	get_node("CPUParticles2D").emitting = true
