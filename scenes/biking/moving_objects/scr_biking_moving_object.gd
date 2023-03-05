class_name BikingMovingObject extends Node2D

signal will_delete
signal coin_got

@export var decorative := false

var speed := 200
var start_position : Vector2

var moving := true
var following := false

@export_enum("Delete", "Signal and delete") var screen_exit_behaviour : int = 0


func _init() -> void:
	add_to_group("speedsters")


func _ready() -> void:
	start_position = global_position
	set_physics_process(not decorative)


func _physics_process(delta: float) -> void:
	if moving:
		global_position.x -= speed * delta
		if following:
			var target : Node2D = get_tree().get_first_node_in_group("biking_players")
			if not is_instance_valid(target): return
			var target_position := Vector2(target.global_position.x, target.global_position.y)
			look_at(target_position)
			global_position = global_position.move_toward(target_position, delta * speed)
	
	if global_position.x < -60:
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
	if following: return
	global_position = Vector2(176, randi_range(76, 112))
