class_name PlatformerGreg extends CharacterBody2D

enum States {WALK, FALL, JUMP}
const S := States

var speed := 60.0
var friction := 160.0
var air_friction := 10.0
var accel := 600.0
var jump_gravity := 240.0
var fall_gravity := 480.0
var jump := 90.0
var coyote := 0.0
var jump_buffer := 0.0

var state : States

var last_input := Vector2()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	match state:
		S.FALL:
			velocity.x = move_toward(velocity.x, 0.0, delta * air_friction)
			velocity.y = move_toward(velocity.y, fall_gravity, fall_gravity * delta)
			if is_on_floor():
				change_state(S.WALK)
			velocity.x = move_toward(velocity.x, input.x * speed, delta * accel)
			coyote += delta
			jump_buffer -= delta
		S.JUMP:
			velocity.x = move_toward(velocity.x, 0.0, delta * air_friction)
			velocity.y = move_toward(velocity.y, jump_gravity * delta,jump_gravity * delta)
			velocity.x = move_toward(velocity.x, input.x * speed, delta * accel)
			if not Input.is_action_pressed("ui_accept") or velocity.y > 0:
				change_state(S.FALL)
		S.WALK:
			velocity.x = move_toward(velocity.x, 0.0, delta * friction)
			velocity.x = move_toward(velocity.x, input.x * speed, delta * accel)
			if not is_on_floor():
				change_state(S.FALL)
			coyote = 0
			jump_buffer = move_toward(jump_buffer, delta, delta)
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer = delta * 9
	
	if coyote < delta * 4 and jump_buffer >= delta * 3:
		change_state(S.JUMP)
	
	move_and_slide()
	last_input = input


func change_state(to: States) -> void:
	state = to
	if to == S.JUMP:
		velocity.y -= jump
		coyote += 100.0
		jump_buffer = -100
