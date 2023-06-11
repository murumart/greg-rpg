extends Node2D

enum States {STAND, SKITTER, PECK, FLY, MAX}
var state := States.STAND: set = set_state

@onready var sprite := $Sprite
@onready var timer := $BehaviourTimer
@onready var visibility_notifier := $VisibilityNotifier
@onready var area := $DisturbanceArea
@onready var test := $CollisionTest
@onready var flapsound := $FlapSound

var movtarget := Vector2()
var speed := 10
var fear := false


func _ready() -> void:
	set_physics_process(false)
	visibility_notifier.screen_entered.connect(on_screen_changed.bind(true))
	visibility_notifier.screen_exited.connect(on_screen_changed.bind(false))
	timer.timeout.connect(reassess_state)
	area.body_entered.connect(disturbed.unbind(1))
	reassess_state()


func _physics_process(delta: float) -> void:
	match state:
		States.STAND:
			pass
		States.SKITTER, States.FLY:
			global_position = global_position.move_toward(movtarget, delta * speed)
			if global_position.distance_squared_to(movtarget) < 4:
				state = States.STAND
		States.PECK:
			if randf() < 0.05: reassess_state()


func reassess_state() -> void:
	state = randi() % 3 as States
	timer.start(randf() * 3.0)


func set_state(to: States) -> void:
	state = to
	if to == States.SKITTER:
		for i in 20:
			movtarget.x = global_position.x + randf_range(-10, 10)
			movtarget.y = global_position.y + randf_range(-10, 10)
			test.target_position = movtarget
			test.force_raycast_update()
			if not test.get_collider(): break
	if to == States.FLY:
		movtarget.x = global_position.x + randf_range(-2000, 60)
		movtarget.y = global_position.y + randf_range(-1200, -1800)
		speed = 120
	scale.x = -1 + int(movtarget.x < global_position.x) * 2
	sprite.play(States.find_key(to).to_lower())
	sprite.speed_scale = randf_range(0.5, 1.5)


# true: became visible on screen; false: exited screen
func on_screen_changed(to: bool) -> void:
	set_physics_process(to)
	if state == States.FLY:
		queue_free()


func disturbed() -> void:
	if fear: return
	for i in get_tree().get_nodes_in_group("birds"):
		if i.is_physics_processing():
			i.fear = true
			i.timer.stop()
			i.state = States.FLY
			i.flapsound.play()
			DAT.incri("birds_scared", 1)



