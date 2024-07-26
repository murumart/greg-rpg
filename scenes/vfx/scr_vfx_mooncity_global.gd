extends Node2D

var camera: Camera2D
@onready var camera_transform: RemoteTransform2D = $CameraTransform
@onready var old_music := SND.current_song_key


func _ready() -> void:
	SND.current_song_player.stream_paused = true
	camera = get_viewport().get_camera_2d()
	if not is_instance_valid(camera):
		set_physics_process(false)
		return
	camera_transform.remote_path = camera.get_path()
	camera.ignore_rotation = false


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(camera):
		set_physics_process(false)
		return
	camera.zoom = Vector2(1.0 / camera_transform.scale.x, 1.0 / camera_transform.scale.y)


func _shake(amount: float) -> void:
	if not is_instance_valid(camera) or not camera.has_method("add_trauma"):
		return
	camera.add_trauma(amount)


func _resume_music() -> void:
	if not is_instance_valid(SND.current_song_player):
		return
	SND.current_song_player.stream_paused = false
