extends Node2D

@onready var partic: GPUParticles2D = $CanvasGroup/Particles


func particles(amount: float = 0.0265) -> void:
	partic.amount_ratio = amount
