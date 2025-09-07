extends Node2D

const MenBullet = preload("res://scenes/tech/men_bullet.gd")

enum Phase {
	NONE,
	BOMBARDMENT,
	AIR_STRIKE,
	SPEW_RINGS,
}

enum MoveMode {
	STOP,
	FOLLOW,
}

@onready var partic: GPUParticles2D = $CanvasGroup/Particles
@onready var plosive_particles: GPUParticles2D = $PlosiveParticles
@onready var bullet_home: CanvasGroup = $BulletHome

@export var phase := Phase.NONE
@export var move_mode := MoveMode.STOP
@export var move_target: Node2D
@export var bullet_target: CharacterBody2D

var _phase_cycles := 0


func _physics_process(delta: float) -> void:
	_movement(delta)
	_shooting(delta)


var _velocity := Vector2()
func _movement(delta: float) -> void:
	if move_mode == MoveMode.FOLLOW:
		var dist := global_position.distance_squared_to(move_target.global_position)
		var dir := global_position.direction_to(move_target.global_position)

		if dist < 10:
			_velocity += _jitter()
		elif dist < 5000:
			_velocity += dir
		else:
			_velocity = dir * 60.0

		_velocity += _jitter()

		position += _velocity * delta + _jitter()
		_velocity = _velocity.move_toward(Vector2.ZERO, delta * 10.0)


func _jitter() -> Vector2:
	return Vector2(randf_range(-1, 1), randf_range(-1, 1))


var _delay := 0.0
var _phase_progress := 0.0
func _shooting(delta: float) -> void:
	if phase == Phase.SPEW_RINGS:
		_delay -= delta
		if _delay <= 0.0:
			_phase_progress += 1
			_delay = 1.0 - _phase_progress * 0.1
			var r := MenBullet.ring(8, 32.0)
			bullet_home.add_child(r)
			r.global_position = global_position
			r.rotation = (_phase_progress / 12.0) * PI
			if _phase_progress == 12:
				splode()
				_phase_progress = 0
	elif phase == Phase.BOMBARDMENT:
		_delay -= delta
		if _delay <= 0.0:
			_phase_progress += 0.1
			_delay = 0.25
			if _phase_progress >= 3:
				_delay = 0.03
			if _phase_progress >= 10:
				_phase_progress = 0
				_delay = 0.6
			_bombard_bullet()
	elif phase == Phase.AIR_STRIKE:
		_delay -= delta
		if _delay <= 0.0:
			_phase_progress += 1
			_delay = 2.0
			_airstrike()


func _bombard_bullet() -> void:
	var b := MenBullet.inst(Vector2.DOWN.rotated(randf_range(-0.01, 0.01)), 80.0)
	bullet_home.add_child(b)
	b.global_position = global_position
	b.global_position.y += randf_range(-10, 10)
	b.global_position.x += randf_range(-160, 160)


func _airstrike() -> void:
	var pos := bullet_target.global_position
	pos += _jitter() * randfn(2, 1)
	pos += bullet_target.velocity * 1.16
	var p := preload("res://scenes/vfx/vfx_x_attack_physical.tscn").instantiate()
	add_sibling(p)
	p.global_position = pos
	p.rotation = randf() * TAU


func particles(amount: float = 0.0265) -> void:
	partic.amount_ratio = amount


func splode() -> void:
	plosive_particles.restart()
