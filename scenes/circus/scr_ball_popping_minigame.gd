extends Node2D

signal finished

const Ball := preload("res://scenes/circus/poppable_ball.tscn")
const Dart := preload("res://scenes/circus/dart.tscn")

enum States {START, PLAYING, GAMEOVER}
var state := States.START

@onready var lanes: Array[Line2D]
@onready var ball_creation_timer: Timer = $Timers/BallCreationTimer
@onready var pointer: Node2D = $Pointer
const POINTER_MAX_SPEED := 30.0
const POINTER_ACCEL := 12.0
const POINTER_DECEL := 120.0
var pointer_velocity := Vector2()
@onready var _space_state: PhysicsDirectSpaceState2D = null

@onready var balls_label := %BallsLabel
@onready var darts_label := %DartsLabel
var balls_left := 20
var darts_left := 22


func _ready() -> void:
	_update_ui()
	lanes.assign($Lanes.get_children())
	ball_creation_timer.timeout.connect(_create_ball)
	if LTS.get_current_scene() == self:
		start()


func start() -> void:
	_space_state = get_world_2d().direct_space_state
	DAT.capture_player("ballgame")
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		SOL.vfx_damage_number(Vector2.ZERO, "3", Color.WHITE, 3)
		SND.menusound()
	)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		SOL.vfx_damage_number(Vector2.ZERO, "2", Color.WHITE, 3)
		SND.menusound()
	)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		SOL.vfx_damage_number(Vector2.ZERO, "1", Color.WHITE, 3)
		SND.menusound()
	)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		SND.play_song("ball_sounds", 1.0, {"play_from_beginning": true})
		state = States.PLAYING
	)


func _create_ball() -> void:
	if not state == States.PLAYING:
		return
	var ball := Ball.instantiate()
	var lane := lanes.pick_random() as Line2D
	lane.add_child(ball)
	ball.global_position = lane.to_global(lane.get_point_position(0))
	ball.global_position.x -= 24
	ball.missed.connect(_lose)
	_update_ui()


func _test_collision() -> Area2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.collision_mask = 0b100
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.position = pointer.position
	# usually added as ui child right
	if not LTS.get_current_scene() == self:
		params.canvas_instance_id = SOL.get_instance_id()
	var balls := _space_state.intersect_point(params, 1).map(func(a): return a.collider as Area2D)
	balls = balls.filter(func(a):
		return is_instance_valid(a) and a.has_method("explode") and "exploded" in a)
	print(balls)
	if not balls.is_empty():
		return balls[0] as Area2D
	return null


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input:
		pointer_velocity = pointer_velocity.move_toward(
				input * POINTER_MAX_SPEED, delta * POINTER_ACCEL)
	else:
		pointer_velocity = pointer_velocity.move_toward(
				Vector2.ZERO, delta * POINTER_DECEL)
	pointer.global_position += pointer_velocity
	pointer.global_position = pointer.global_position.clamp(Vector2.ZERO,
			Vector2(SOL.SCREEN_SIZE))
	if (Input.is_action_just_pressed("ui_accept")
			and state == States.PLAYING and darts_left > 0):
		SND.play_sound(preload("res://sounds/circus/throw.ogg"))
		var dart := Dart.instantiate()
		add_child(dart)
		darts_left -= 1
		dart.target = pointer.global_position
		dart.global_position.x = pointer.global_position.x
		dart.global_position.y = 140
		var ball := _test_collision()
		_update_ui()
		if not is_instance_valid(ball):
			return
		ball.explode()
		balls_left -= 1
		if balls_left <= 0:
			_win()
		_update_ui()


func _lose() -> void:
	state = States.GAMEOVER
	get_tree().call_group("poppable_balls", "queue_free")
	SND.play_sound(preload("res://sounds/pennistong/pennistong_lose.ogg"))
	SND.play_song("", 2.0)
	await Math.timer(1.0)
	SOL.dialogue("ballgame_lose")
	await SOL.dialogue_closed
	DAT.free_player("ballgame")
	finished.emit()
	disappear()


func _win() -> void:
	state = States.GAMEOVER
	get_tree().get_nodes_in_group("poppable_balls").map(func(a):
		if not a.exploded: a.queue_free())
	SND.play_sound(preload("res://sounds/pennistong/pennistong_win.ogg"))
	SND.play_song("", 2.0)
	await Math.timer(1.0)
	SOL.dialogue("ballgame_win")
	var greg := ResMan.get_character("greg")
	greg.add_experience(greg.xp2lvl(greg.level + 1), true)
	await SOL.dialogue_closed
	DAT.free_player("ballgame")
	finished.emit()
	disappear()


func disappear() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)


func _update_ui() -> void:
	balls_label.text = str(balls_left)
	darts_label.text = str(darts_left)

