class_name BikingMovingObject extends Node2D

var speed := 200
var start_position : Vector2

var moving := true

@export_enum("Delete", "Loop") var screen_exit_behaviour : int = 0


func _init() -> void:
	add_to_group("speedsters")


func _ready() -> void:
	start_position = global_position


func _physics_process(delta: float) -> void:
	if moving: global_position.x -= speed * delta
	
	if global_position.x < -20:
		if screen_exit_behaviour == 0:
			queue_free()
		else:
			global_position = start_position
