extends RigidBody2D

var lifetime := 0.0
const MAX_LIFETIME := 2.0

var paper_sounds := [
	preload("res://sounds/paper/paper3.ogg"),
	preload("res://sounds/paper/paper5.ogg"),
	preload("res://sounds/paper/paper6.ogg"),
]


func _ready() -> void:
	apply_torque_impulse(randf_range(300, 3000))


func _physics_process(delta: float) -> void:
	lifetime += delta
	
	if lifetime > MAX_LIFETIME:
		call_deferred("queue_free")


func _on_body_entered(_body: Node) -> void:
	SND.play_sound(paper_sounds.pick_random(), {"volume": -16, "pitch": randf_range(0.9, 1.3)})
	$CollisionShape2D.set_deferred("disabled", true)
