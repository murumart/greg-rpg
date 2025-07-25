extends Node2D

@onready var thug_overworld: CharacterBody2D = $ThugOverworld


func _ready() -> void:
	if LTS.gate_id not in [&"town-mayor", LTS.GATE_LOADING]:
		thug_overworld.queue_free()
