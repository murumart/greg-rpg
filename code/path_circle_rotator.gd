extends Node

@export var path: Path2D
@export var followers: Array[PathFollow2D]
@export var speed := 0.1


func _ready() -> void:
	var r := 1.0 / followers.size()
	for f in followers.size():
		followers[f].progress_ratio = r * f


func _physics_process(delta: float) -> void:
	for f in followers:
		f.progress_ratio += speed * delta
