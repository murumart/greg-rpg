extends RigidBody2D

# the envelopes that fly about

var lifetime := 0.0
const MAX_LIFETIME := 2.0
const FOLLOW_SPEED := 60

var paper_sounds := [
	preload("res://sounds/paper/paper3.ogg"),
	preload("res://sounds/paper/paper5.ogg"),
	preload("res://sounds/paper/paper6.ogg"),
]

var saucy := false
var following := false
var bounces := 0
var bounce_limit := 1


func _ready() -> void:
	apply_torque_impulse(randf_range(300, 3000))


func _physics_process(delta: float) -> void:
	lifetime += delta

	if lifetime > MAX_LIFETIME:
		call_deferred("queue_free")

	# follow the mailboxes (when you have that one perk)
	if following:
		var target: Node2D = get_tree().get_first_node_in_group("biking_mailboxes")
		if not is_instance_valid(target):
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			freeze = false
			return
		if $CollisionShape2D.disabled:
			$CollisionShape2D.set_deferred("disabled", false)
		# manually move it, not using physics
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		freeze = true
		var target_position := Vector2(target.global_position.x,
				target.global_position.y - 15)
		look_at(target_position)
		global_position = global_position.move_toward(
				target_position, delta * FOLLOW_SPEED *
				(2.0 - int(target_position.x >= global_position.x)))
		lifetime -= delta * 0.5

		if global_position.is_equal_approx(target_position):
			queue_free()


func _on_body_entered(_body: Node) -> void:
	if freeze:
		return
	bounces += 1
	SND.play_sound(paper_sounds.pick_random(), {"volume": -16, "pitch_scale": randf_range(0.9, 1.3)})
	if bounces >= bounce_limit:
		$CollisionShape2D.set_deferred("disabled", true)
	if saucy:
		$SaucyParticles.amount_ratio = 1
		create_tween().tween_property($SaucyParticles, "amount_ratio", 0.169, 0.1)


func set_saucy() -> void:
	physics_material_override.bounce = 1.0
	physics_material_override.friction = 0.05
	mass = 0.2
	$SaucyParticles.emitting = true
	$Sprite2D.modulate = Color.INDIAN_RED
	bounce_limit = 3
