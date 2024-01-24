extends CharacterBody2D

enum Poses {NORMAL, TRICK, TRACK, HEAD}

signal did_trick(pts: int)
signal broadcast_balance(balance: float)

var speed := 3000.0
var friction := 30.0
var jump_height := 15.0
var balance := 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.5

@onready var jump_case: RayCast2D = $JumpCase
@onready var sprite: Sprite2D = $Sprite2D
@onready var balance_right: RayCast2D = $BalanceRight
@onready var balance_left: RayCast2D = $BalanceLeft
@onready var camera: Camera2D = $PlayerCamera


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not test_floor():
		velocity.y += gravity * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and test_floor():
		velocity.y = -jump_height * sqrt(Vector2(velocity.x * 0.33, velocity.y).length())
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * delta
		balance += velocity.x * 0.001 * delta
		sprite.scale.x = signf(velocity.x)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	if Input.is_action_pressed("ui_menu"):
		balance += direction * delta * absf(velocity.y) * 0.2 * absf(balance)
	if Input.is_action_just_pressed("ui_cancel"):
		trick()
	mod_balance(delta * 0.333)
	sprite_look()
	
	move_and_slide()


func test_floor() -> bool:
	jump_case.force_raycast_update()
	var coll := jump_case.get_collider()
	if coll:
		return true
	return false


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
	camera.make_current()
	trick()


func trick() -> void:
	var t := create_tween().set_trans(Tween.TRANS_CUBIC)
	t.tween_property(sprite, "scale", Vector2(signf(sprite.scale.x) * 1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "scale", Vector2(signf(sprite.scale.x) * 1, 1), 0.05)
	if randf() < 0.25:
		camera.make_current()


func sprite_look(force_cool := false) -> void:
	sprite.rotation = balance * PI
	if absf(balance) > 0.6 and test_floor():
		sprite.region_rect.position.x = 16 * int(Poses.HEAD)
	if force_cool:
		sprite.region_rect.position.x = 16 * ((randi() % 2) + 1)
	if absf(balance) - 0.3 < 0:
		sprite.region_rect.position.x = 16 * Poses.NORMAL
	elif absf(balance) - 0.6 < 0:
		sprite.region_rect.position.x = 16 * Poses.TRACK

