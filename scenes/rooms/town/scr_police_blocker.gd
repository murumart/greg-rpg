extends Node2D

@onready var detect := $DetectionArea as Area2D
@onready var anim := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	detect.body_entered.connect(func(_a):
		anim.play("slide")
	)
	detect.body_exited.connect(func(_a):
		anim.play_backwards("slide")
	)
