extends Node2D

## this shit causes error spam in Vector2::normalize
##
## can't fix it!!

@export var is_visible_notif: VisibleOnScreenNotifier2D

@onready var baller_1: CharacterBody2D = $"Baller1"
@onready var baller_2: CharacterBody2D = $"Baller2"
@onready var ball: RigidBody2D = $Ball

@onready var ballers := [baller_1, baller_2]

@export var greg: PlayerOverworld
@export var camera: Camera2D
@onready var camera_area: Area2D = $CameraArea
@onready var cam_center: Vector2 = $CamCenter.global_position


func _ready() -> void:
	is_visible_notif.screen_exited.connect(_screen_exited)
	is_visible_notif.screen_entered.connect(_screen_entered)
	camera_area.body_entered.connect(_camera_area_entered)
	camera_area.body_exited.connect(_camera_area_exited)


func _screen_entered() -> void:
	show()
	for b in ballers:
		b.set_physics_process(true)


func _screen_exited() -> void:
	hide()
	for b in ballers:
		b.set_physics_process(false)


func _camera_area_entered(thing: Node2D) -> void:
	if not thing == greg:
		return
	var pos := camera.global_position
	greg.remove_child(camera)
	add_child(camera)
	#camera.global_position = pos
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "global_position", cam_center, 1.0).from(pos)


func _camera_area_exited(thing: Node2D) -> void:
	if thing == ball:
		var tw := create_tween()
		tw.tween_property(ball, "global_position", cam_center, 0.5)
		tw.tween_callback(ball.force_update_transform)
		ball.set_axis_velocity(Vector2.ZERO)
		return
	if not thing == greg:
		return
	var pos := camera.global_position
	remove_child(camera)
	greg.add_child(camera)
	camera.global_position = pos
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "position", Vector2.ZERO, 1.0)
