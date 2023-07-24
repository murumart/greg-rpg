class_name PenniStong extends Node2D

var paddle_speed := 60.0
var paddle_width := 32

enum {ROCK, PAPER, SCISSORS}
const RPS_REGS := [Rect2(32, 0, 32, 32), Rect2(0, 32, 32, 32), Rect2(0, 0, 32, 32)]
const RPS_TEXTURE := preload("res://sprites/penni_stong/rps.png")
const SOUNDS := [preload("res://sounds/pennistong/bounce.ogg"),
	preload("res://sounds/pennistong/epos.ogg"),
	preload("res://sounds/pennistong/ppos.ogg"),
	preload("res://sounds/pennistong/tie.ogg"),
	preload("res://sounds/pennistong/pongend.ogg")
]

@onready var paddle_u := $Paddles/Upper as AnimatableBody2D
@onready var paddle_l := $Paddles/Lower as AnimatableBody2D
@onready var paddles := [paddle_u, paddle_l]
@onready var ball := $Ball as CharacterBody2D
var bdir := Vector2()

var rps_open := false
@onready var rps_ui: Node2D = $RpsUi
var rps_choice := 0
var ball_stored_choice := 0

var score := 0:
	set(to):
		score = to
		$UI/S/Player/Score.text = "score: " + str(score)
var enscore := 0:
	set(to):
		enscore = to
		$UI/S/Enemy/Score.text = "score: " + str(enscore)


func _ready() -> void:
	for p in paddles:
		((p.get_child(1) as CollisionShape2D).shape
		as RectangleShape2D).size.x = paddle_width
	bdir = Vector2.DOWN


func _physics_process(delta: float) -> void:
	if not rps_open:
		_paddle_movement(delta)
		_ai_paddle(delta)
		_ball_movement(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if rps_open:
		var old_choice := rps_choice
		var input := Input.get_axis("ui_left", "ui_right")
		rps_choice = wrapi(rps_choice + input, 0, 3)
		rps_select(rps_choice)
		if old_choice != rps_choice:
			SND.menusound()
		if event.is_action_pressed("ui_accept"):
			if rps_a_wins(ball_stored_choice, rps_choice):
				enscore += 100
				SND.play_sound(SOUNDS[1])
			elif rps_a_wins(rps_choice, ball_stored_choice):
				score += 100
				SND.play_sound(SOUNDS[2])
			else:
				SND.play_sound(SOUNDS[3])
			ball_stored_choice = rps_choice
			close_rps()


func _paddle_movement(delta: float) -> void:
	var input := Input.get_axis("move_left", "move_right")
	paddle_l.global_position.x = clampf(
		paddle_l.global_position.x + (paddle_speed * delta * input),
		paddle_width / 2, 160 - paddle_width / 2
	)


func _ai_paddle(delta: float) -> void:
	var ballpos := ball.global_position
	paddle_u.global_position.x = clampf(move_toward(
		paddle_u.global_position.x, ballpos.x, paddle_speed * delta
	), paddle_width / 2, 160 - paddle_width / 2)


var ignored_shape
var stuck := 0.0
func _ball_movement(delta: float) -> void:
	ball.modulate.r = 1 - stuck / 10
	var bpos := ball.global_position
	var bvos := bdir * paddle_speed * delta
	var coll := ball.move_and_collide(bvos, false, 0.01, true)
	if bpos == ball.global_position:
		ball.global_position +=  Vector2(randf_range(-1, 1), randf_range(-1, 1)) * stuck
	if coll:
		if coll.get_collider_shape() == ignored_shape:
			stuck += delta
			bdir += Vector2(randf_range(-1, 1), randf_range(-1, 1) * 2) * stuck
		elif bpos.y > 120 or bpos.y < 0:
			set_physics_process(false)
			SND.play_sound(SOUNDS[4])
		elif (coll.get_normal().is_equal_approx(Vector2.UP) or
		coll.get_normal().is_equal_approx(Vector2.DOWN)):
			bdir = Vector2((randf_range(-1, 1) * 1 if randf() <= 0.95 else
			randf_range(1, 3)), -bdir.y)
			paddle_speed *= 1.01
			# player handling
			if bpos.y > 60:
				open_rps()
				
			# enemy handling
			else:
				var rps := randi() % 3
				if rps_a_wins(rps, ball_stored_choice):
					enscore += 100
					SND.play_sound(SOUNDS[1])
				elif rps_a_wins(ball_stored_choice, rps):
					score += 100
					SND.play_sound(SOUNDS[2])
				else:
					SND.play_sound(SOUNDS[3])
				ball_stored_choice = rps
		else:
			bdir = Vector2(-bdir.x, bdir.y)
		SND.play_sound(SOUNDS[0])
		ignored_shape = coll.get_collider_shape()


func open_rps(where := Vector2(80, 60)) -> void:
	rps_open = true
	rps_ui.show()
	rps_ui.global_position = where
	rps_select(ROCK)


func close_rps() -> void:
	rps_open = false
	rps_ui.hide()


func rps_select(which: int) -> void:
	for i in rps_ui.get_children():
		i.modulate = Color(0.4, 0.4, 0.4)
		var tw := create_tween()
		tw.tween_property(i, "scale", Vector2(0.8, 0.8), 0.1)
	which = wrapi(which, 0, 3)
	rps_ui.get_child(which).modulate = Color.WHITE
	var tw := create_tween()
	tw.tween_property(rps_ui.get_child(which), "scale", Vector2(1.0, 1.0), 0.1)


func rps_a_wins(a: int, b: int) -> bool:
	if a == ROCK and b == SCISSORS:
		return true
	if a == PAPER and b == ROCK:
		return true
	if a == SCISSORS and b == PAPER:
		return true
	return false


