extends CharacterBody2D

const S_1 = preload("res://sounds/skating/s1.ogg"); const S_2 = preload("res://sounds/skating/s2.ogg")
const S_3 = preload("res://sounds/skating/s3.ogg"); const S_4 = preload("res://sounds/skating/s4.ogg")
const S_5 = preload("res://sounds/skating/s5.ogg"); const S_6 = preload("res://sounds/skating/s6.ogg")
const S_7 = preload("res://sounds/skating/s7.ogg"); const S_8 = preload("res://sounds/skating/s8.ogg")
const S_9 = preload("res://sounds/skating/s9.ogg"); const S_10 = preload("res://sounds/skating/s10.ogg")
const S_11 = preload("res://sounds/skating/s11.ogg"); const S_12 = preload("res://sounds/skating/s12.ogg")
const S_13 = preload("res://sounds/skating/s13.ogg"); const S_14 = preload("res://sounds/skating/s14.ogg")
const S_15 = preload("res://sounds/skating/s15.ogg"); const S = preload("res://sounds/skating/s.ogg")

const CameraType = preload("res://scenes/tech/scr_camera.gd")

enum Poses {NORMAL, TRICK, TRACK, HEAD}

signal did_trick(pts: int)
signal broadcast_balance(balance: float)
signal broadcast_boredom(boredom: float)
signal game_over

var speed := 3000.0
var friction := 30.0
var jump_height := 15.0
var balance := 0.0
var boredom := 0.0
var in_air := false
var air_time := 0.0
var did_flip_during_air := false
var headstand := false
var playtime := 0.0
var can_input := true
var flips_in_air := 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.5

@onready var jump_case: RayCast2D = $JumpCase
@onready var sprite: Sprite2D = $Sprite2D
@onready var balance_right: RayCast2D = $BalanceRight
@onready var balance_left: RayCast2D = $BalanceLeft
@onready var camera := $PlayerCamera as CameraType
@onready var jump_sound: AudioStreamPlayer = $JumpSound


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not test_floor():
		velocity.y += gravity * delta
		jump_sound.pitch_scale = maxf(remap(velocity.y, -300.0, 100.0, 3, 0.2), 0.2)
	if test_floor():
		in_air = false
		if flips_in_air:
			did_trick.emit(flips_in_air)
			text("%s flips!!" % flips_in_air)
		flips_in_air = 0
		if did_flip_during_air:
			SND.play_sound(S_6)
			if absf(balance) < 0.06:
				text("perfect landing!!", Color.DARK_SEA_GREEN)
				trick()
				SND.play_sound(S_8)
				did_trick.emit(700)
		did_flip_during_air = false
		var new_pts := ceili(air_time * 10)
		if new_pts:
			did_trick.emit(new_pts)
		if new_pts > 15:
			text("unreal air!!!!", Color.GOLD)
			SND.play_sound(S_15)
		elif new_pts > 6:
			text("air!!!")
		air_time = 0.0
		jump_sound.stop()

	# Handle jump.
	if can_input and Input.is_action_just_pressed("ui_accept"):
		if can_jump():
			jump()
		elif test_floor():
			SND.play_sound(S_9)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if can_input and direction:
		velocity.x = direction * speed * delta
		balance += velocity.x * 0.001 * delta
		sprite.scale.x = signf(velocity.x)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	if can_input and Input.is_action_pressed("menu"):
		balance += direction * delta * absf(velocity.y) * 0.2 * maxf(absf(balance) * 2, 0.2)
	if can_input and Input.is_action_just_pressed("cancel"):
		trick()
	mod_balance(delta * 0.333)
	sprite_look()

	move_and_slide()
	if can_input:
		boredom = maxf(boredom + delta * playtime * 0.1, 0.0)
	broadcast_boredom.emit(boredom)
	if boredom >= 10.0 and can_input:
		can_input = false
		SND.play_sound(S)
		game_over.emit()
	if in_air:
		air_time += delta
	playtime += delta


func test_floor() -> bool:
	jump_case.force_raycast_update()
	var coll := jump_case.get_collider()
	if coll:
		return true
	return false


func can_jump():
	return test_floor() and absf(balance) < 0.4


func jump() -> void:
	velocity.y = -jump_height * sqrt(Vector2(velocity.x * 0.33, velocity.y).length())
	velocity.x += Vector2.from_angle(balance * PI).x * jump_height * sqrt(Vector2(velocity.x * 0.33, velocity.y).length())
	if velocity.y < -0.1:
		boredom -= 3
		in_air = true
		jump_sound.play()


func mod_balance(delta: float) -> void:
	var rcol := balance_right.get_collider()
	var lcol := balance_left.get_collider()
	if rcol:
		balance -= delta
	if lcol:
		balance += delta

	if absf(balance) >= 1.0:
		balance = -signf(balance) * 0.999
		if not test_floor():
			flip()

	broadcast_balance.emit(balance)


func flip() -> void:
	sprite_look(true)
	velocity.y -= 150.0
	trick()
	did_trick.emit(100)
	boredom = 0.0
	in_air = true
	did_flip_during_air = true
	flips_in_air += 1
	if flips_in_air == 30:
		SOL.vfx("explosion", Vector2(), {"parent": self})
	text("flip!!! " + str(flips_in_air), Color.AQUAMARINE, {"size": 0.5})
	SND.play_sound(S_5)
	if velocity.y < 0:
		SND.play_sound(S_2)


func trick() -> void:
	var t := create_tween().set_trans(Tween.TRANS_CUBIC)
	t.tween_property(sprite, "scale", Vector2(signf(sprite.scale.x) * 1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "scale", Vector2(signf(sprite.scale.x) * 1, 1), 0.05)
	if randf() < 0.25:
		camera.make_current()
	camera.add_trauma(0.3)


func sprite_look(force_cool := false) -> void:
	sprite.rotation = balance * PI
	if absf(balance) > 0.6 and test_floor():
		if not headstand:
			SND.play_sound(S_11)
			headstand = true
		sprite.region_rect.position.x = 16 * int(Poses.HEAD)
	if force_cool:
		sprite.region_rect.position.x = 16 * ((randi() % 2) + 1)
		headstand = false
	if absf(balance) - 0.3 < 0:
		sprite.region_rect.position.x = 16 * Poses.NORMAL
		headstand = false
	elif absf(balance) - 0.6 < 0:
		sprite.region_rect.position.x = 16 * Poses.TRACK
		headstand = false


func text(txt: String, col: Color = Color.WHITE, options := {}) -> void:
	options.merge({"color": col, "parent": self, "text": txt})
	SOL.vfx("damage_number", Vector2(0, -24), options)

