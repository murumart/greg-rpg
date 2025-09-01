extends Area2D

@export var camera: Camera2D

@export var limit_left: int = -99999999
@export var limit_right: int = 99999999
@export var limit_top: int = -99999999
@export var limit_bottom: int = 99999999

var _old_left: int
var _old_right: int
var _old_top: int
var _old_bottom: int


func _ready() -> void:
	body_entered.connect(func(__: Node) -> void:
		_old_left = camera.limit_left
		_old_right = camera.limit_right
		_old_top = camera.limit_top
		_old_bottom = camera.limit_bottom

		camera.limit_left = limit_left
		camera.limit_right = limit_right
		camera.limit_bottom = limit_bottom
		camera.limit_top = limit_top
	)
	body_exited.connect(func(__: Node) -> void:
		camera.limit_left = _old_left
		camera.limit_right = _old_right
		camera.limit_bottom = _old_bottom
		camera.limit_top = _old_top
	)
