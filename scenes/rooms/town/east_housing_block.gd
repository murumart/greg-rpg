extends Node2D

@onready var camera_area: Area2D = $CameraArea

@export var cam: Camera2D

var time := 0.75


func _ready() -> void:
	camera_area.body_entered.connect(_cam_in.unbind(1))
	camera_area.body_exited.connect(_cam_out.unbind(1))


func _cam_in() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"global_position:y", global_position.y + 28, time)


func _cam_out() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"position:y", -9, time)
