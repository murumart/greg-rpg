class_name PlatformerEnemyMovingComponent extends Node

var STATS := preload("res://scenes/mining/scr_platformer_stats.gd").new()

enum States {WALK, FALL, JUMP}
const S := States

var coyote := 0.0
var jump_buffer := 0.0

var state: States

var direction := Vector2(1, 0)

@export var target: CharacterBody2D
@export var visual: Node2D
@export var edge_shape_cast: ShapeCast2D
@export var walk_speed: float



func _ready() -> void:
	assert(target)
	if walk_speed:
		STATS.SPEED = walk_speed


func _physics_process(delta: float) -> void:
	match state:
		S.FALL:
			target.velocity.x = move_toward(target.velocity.x, 0.0, delta * STATS.AIR_FRICTION)
			target.velocity.y = move_toward(target.velocity.y, STATS.FALL_GRAVITY, STATS.FALL_GRAVITY * delta)
			if target.is_on_floor():
				change_state(S.WALK)
			target.velocity.x = move_toward(target.velocity.x, direction.x * STATS.SPEED, delta * STATS.ACCEL)
			coyote += delta
			jump_buffer -= delta
		S.JUMP:
			target.velocity.x = move_toward(target.velocity.x, 0.0, delta * STATS.AIR_FRICTION)
			target.velocity.y = move_toward(target.velocity.y, STATS.JUMP_GRAVITY * delta, STATS.JUMP_GRAVITY * delta)
			target.velocity.x = move_toward(target.velocity.x, direction.x * STATS.SPEED, delta * STATS.ACCEL)
			if not Input.is_action_pressed("ui_accept") or target.velocity.y > 0:
				change_state(S.FALL)
		S.WALK:
			target.velocity.x = move_toward(target.velocity.x, 0.0, delta * STATS.FRICTION)
			target.velocity.x = move_toward(target.velocity.x, direction.x * STATS.SPEED, delta * STATS.ACCEL)
			if not target.is_on_floor():
				change_state(S.FALL)
			coyote = 0
			jump_buffer = move_toward(jump_buffer, delta, delta)
	
	if coyote < delta * 4 and jump_buffer >= delta * 3:
		change_state(S.JUMP)
	
	target.move_and_slide()
	if test_collision(Vector2.RIGHT):
		direction.x = -1
		if visual:
			visual.scale.x = 1
	elif test_collision(Vector2.LEFT):
		direction.x = 1
		if visual:
			visual.scale.x = -1


func jump(delta: float) -> void:
	jump_buffer = delta * 9


func change_state(to: States) -> void:
	state = to
	if to == S.JUMP:
		target.velocity.y -= STATS.JUMP
		coyote += 100.0
		jump_buffer = -100
	elif to == S.FALL or to == S.JUMP:
		pass
	elif to == S.WALK:
		pass


func test_collision(side: Vector2) -> bool:
	edge_shape_cast.target_position = side * 1
	edge_shape_cast.force_shapecast_update()
	var coll := edge_shape_cast.is_colliding()
	return coll
