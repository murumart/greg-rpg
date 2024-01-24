extends Node2D

const CameraType := preload("res://scenes/tech/scr_camera.gd")
const PlayerType := preload("res://scenes/skating/player.gd")
const UIType := preload("res://scenes/skating/ui.gd")

var points := 0

var camera_timer := Timer.new()
@onready var ui := $UI as UIType
@onready var camera := $MainCamera as CameraType
@onready var player := $Player as PlayerType


func _ready() -> void:
	remove_child(ui)
	SOL.add_ui_child(ui)
	add_child(camera_timer)
	camera_timer.start(1)
	camera_timer.timeout.connect(_camera_timeout)
	camera.make_current()
	player.broadcast_balance.connect(ui.display_balance)


func _camera_timeout() -> void:
	camera.make_current()
	camera_timer.start(randf_range(1.0, 10.0))
