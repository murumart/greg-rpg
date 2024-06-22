extends Node2D

var direction := Vector2()
var speed := 120.0


func init(options := {}) -> void:
	if not options.get("silent", false):
		$FlapSound.play()
	if not options.get("forever", false):
		$Timer.start(2.0)
	direction = options.get("direction", Vector2(-randf(), -randf()).normalized())
	speed = options.get("speed", randf_range(120.0, 170.0))
	$GPUParticles2D.emitting = true


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
