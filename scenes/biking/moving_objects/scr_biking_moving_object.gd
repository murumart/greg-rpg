class_name BikingMovingObject extends Node2D

signal will_delete
signal coin_got

var speed := 200
var start_position : Vector2

var moving := true

@export_enum("Delete", "Signal and delete") var screen_exit_behaviour : int = 0


func _init() -> void:
	add_to_group("speedsters")


func _ready() -> void:
	start_position = global_position


func _physics_process(delta: float) -> void:
	if moving: global_position.x -= speed * delta
	
	if global_position.x < -20:
		if screen_exit_behaviour == 1:
			will_delete.emit()
		queue_free()


func collect_coin() -> void:
	coin_got.emit()
	delete()


func delete() -> void:
	will_delete.emit()
	queue_free()


func randomise_position() -> void:
	global_position = Vector2(176, randi_range(76, 112))
