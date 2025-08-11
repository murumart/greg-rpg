extends Node

@export var path: Path2D
@export var speed := 0.1

var followers: Array[PathFollow2D]


func _ready() -> void:
	followers.assign(path.get_children())
	var r := 1.0 / followers.size()
	for f in followers.size():
		followers[f].progress_ratio = r * f


func _physics_process(delta: float) -> void:
	for f in followers:
		f.progress_ratio += speed * delta
