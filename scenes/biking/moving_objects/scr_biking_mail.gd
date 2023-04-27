extends RigidBody2D

# the envelopes that fly about

var lifetime := 0.0
const MAX_LIFETIME := 2.0

var paper_sounds := [
	preload("res://sounds/paper/paper3.ogg"),
	preload("res://sounds/paper/paper5.ogg"),
	preload("res://sounds/paper/paper6.ogg"),
]

var following := false


func _ready() -> void:
	apply_torque_impulse(randf_range(300, 3000))


func _physics_process(delta: float) -> void:
	lifetime += delta
	
	if lifetime > MAX_LIFETIME:
		call_deferred("queue_free")
	
	# follow the mailboxes (when you have that one perk)
	if following:
		var target : Node2D = get_tree().get_first_node_in_group("biking_mailboxes")
		if not is_instance_valid(target):
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			freeze = false
			return
		if $CollisionShape2D.disabled:
			$CollisionShape2D.set_deferred("disabled", false)
		# manually move it, not using physics
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		freeze = true
		var target_position := Vector2(target.global_position.x, target.global_position.y - 15)
		look_at(target_position)
		global_position = global_position.move_toward(target_position, delta * 60)
		lifetime -= delta * 0.5
		
		if global_position.is_equal_approx(target_position):
			queue_free()


func _on_body_entered(_body: Node) -> void:
	if freeze: return
	SND.play_sound(paper_sounds.pick_random(), {"volume": -16, "pitch": randf_range(0.9, 1.3)})
	$CollisionShape2D.set_deferred("disabled", true)
