extends Node2D

@export var cat: OverworldCharacter
@export var beam: Node2D
@export var raycasts: Array[RayCast2D]

var speed := 0.0
var desired_angle := 0.0
var default_length := 0.0
var draw_beam := false


func _ready() -> void:
	speed = (sin(hash(global_position) - cos(hash(global_position))) * 0.5 + 1.0) * 4.0
	var dist := 0.0
	for rc in raycasts:
		dist += rc.target_position.length()
	default_length = dist / raycasts.size()


func _physics_process(delta: float) -> void:
	rotation = move_toward(rotation, desired_angle, delta * speed)
	beam.hide()
	match cat.state:
		cat.States.IDLE:
			if randf() * speed * delta < 0.0001:
				desired_angle = randf_range(-TAU, TAU)
			if draw_beam:
				_beam_visual(delta)
				_test_greg()


func _beam_visual(delta: float) -> void:
	var dist := 0.0
	for rc in raycasts:
		var dp := 0.0
		if not rc.is_colliding():
			dp = default_length
		else:
			var point := rc.get_collision_point()
			dp = minf(point.distance_to(global_position), default_length)
			desired_angle += speed * delta
		dist += dp
	dist /= raycasts.size()
	beam.scale.y = move_toward(beam.scale.y, dist / default_length, delta * 20.0)
	beam.show()


func _test_greg() -> void:
	for rc in raycasts:
		var collider := rc.get_collider()
		if not collider or not collider is PlayerOverworld:
			continue
		cat.chase_target = collider
		cat.chase(collider)
		SND.play_sound(preload("res://sounds/cat_notice.ogg"), {"volume": 10})
		set_physics_process(false)
		hide()
		create_tween().tween_interval(5).finished.connect(func():
			set_physics_process(true)
		)
		break


#func _draw() -> void:
	#for rc in raycasts:
		#var point := rc.get_collision_point()
		#if not rc.is_colliding():
			#point = to_global(rc.target_position.rotated(rc.rotation))
		#draw_circle(to_local(point), 2, Color.WHITE)


func _on_visibility_screen_entered() -> void:
	draw_beam = true


func _on_visibility_screen_exited() -> void:
	draw_beam = false
