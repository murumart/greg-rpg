extends Node2D

const MenBullet = preload("res://scenes/tech/men_bullet.gd")

enum Phase {
	NONE,
	SHOOT,
	BOMBARDMENT,
	SPEW_RINGS,
	AIR_STRIKE,
	SWOOP,
	MAX
}

enum MoveMode {
	STOP,
	FOLLOW,
	SWOOP,
}

const S_EEP = preload("res://sounds/x/eep.ogg")
const S_HEH = preload("res://sounds/x/heh.ogg")
const S_HMPH = preload("res://sounds/x/hmph.ogg")
const S_EHEH = preload("res://sounds/x/eheh.ogg")

@onready var attack_shape: CollisionShape2D = $Area2D/AttackShape
@onready var partic: GPUParticles2D = $DarkDisplay/Particles
@onready var plosive_particles: GPUParticles2D = $PlosiveParticles
@onready var bullet_home: CanvasGroup = $BulletHome
@onready var swoop_sound: AudioStreamPlayer = $SwoopSound
@onready var explode_sound: AudioStreamPlayer = $ExplodeSound
@onready var blare_sound: AudioStreamPlayer = $BlareSound
@onready var bullet_sound: AudioStreamPlayer = $BulletSound
@onready var dark_display: CanvasGroup = $DarkDisplay
@onready var light_display: Node2D = $mdp
@onready var mdpsprite: AnimatedSprite2D = $mdp/mdp
@onready var shake_sound: AudioStreamPlayer = $mdp/ShakeSound
@onready var giggle_snd: AudioStreamPlayer = $mdp/Giggle1
@onready var speech_snd: AudioStreamPlayer = $mdp/Speech

@export var phase := Phase.NONE
@export var move_mode := MoveMode.STOP
@export var move_target: Node2D
@export var bullet_target: CharacterBody2D

var _phase_cycles := 0


var _swoop_progress: float
var _swoop_start: Vector2
var _swoop_dir: int
var _swoop_arc: float
var _swoop_dip: float
func _physics_process(delta: float) -> void:
	if move_mode == MoveMode.FOLLOW:
		show()
		_movement(delta)
	elif move_mode == MoveMode.SWOOP:
		show()
		_swoop_movement(_swoop_progress, _swoop_arc, _swoop_dip, _swoop_start, _swoop_dir)
	_shooting(delta)


var _velocity := Vector2()
func _movement(delta: float) -> void:
	var target := move_target.global_position
	if phase == Phase.BOMBARDMENT:
		target.y -= 50
	var dist := global_position.distance_squared_to(target)
	var dir := global_position.direction_to(target)

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
			var t := create_tween().set_loops(6)
			t.tween_interval(0.006)
			t.tween_callback(bullet_sound.play)
			bullet_sound.play()
			r.global_position = global_position
			r.rotation = (_phase_progress / 12.0) * PI
			if _phase_progress > 7 and not swoop_sound.playing:
				swoop_sound.pitch_scale = 3.0
				swoop_sound.play()
			if _phase_progress == 12:
				splode()
				if not explode_sound.playing:
					explode_sound.pitch_scale = 1.13
					explode_sound.play()
				_phase_progress = 0
				_phase_cycles += 1
		if _phase_cycles >= 3:
			_switch_phase()
	elif phase == Phase.SHOOT:
		_delay -= delta
		if _delay <= 0.0:
			_delay = 0.33 - _phase_progress * 0.05
			_phase_progress += 1.0
			var t := create_tween().set_loops(roundi(_phase_progress * 0.5))
			t.tween_interval(0.03)
			t.tween_callback(_shoot_bullet)
		if _phase_progress >= 8:
			_phase_progress = 0.0
			_phase_cycles += 1
			_delay = 1.6
		if _phase_cycles >= 4:
			_switch_phase()
	elif phase == Phase.BOMBARDMENT:
		_delay -= delta
		if _delay <= 0.0:
			_phase_progress += 0.1
			_delay = 0.15 - randf() * 0.05
			if _phase_progress >= 3:
				_delay = 0.03 - randf() * 0.01
				if not blare_sound.playing:
					blare_sound.play()
			if _phase_progress >= 10:
				_phase_progress = 0
				_phase_cycles += 1
				_delay = 0.6
			_bombard_bullet()
		if _phase_cycles >= 2:
			_switch_phase()
	elif phase == Phase.AIR_STRIKE:
		_delay -= delta
		if _delay <= 0.0:
			_phase_progress += 1
			_delay = 2.0
			if _phase_progress >= 5:
				_phase_cycles += 1
				_phase_progress = 0
			if _phase_progress >= 3:
				_delay = 0.5
			_airstrike()
			if _phase_cycles >= 2:
				_switch_phase()
	elif phase == Phase.SWOOP:
		_delay -= delta
		if _delay <= 0.0:
			_delay = 999.0
			move_mode = MoveMode.SWOOP
			_swoop_start = global_position
			_swoop_progress = 0.0
			_swoop_dir = 1 if global_position.x < bullet_target.global_position.x else -1
			_swoop_arc = absf(global_position.x - bullet_target.global_position.x) * 2.0
			_swoop_dip = bullet_target.global_position.y - global_position.y
			particles(1.0)
			attack_shape.disabled = false
			swoop_sound.pitch_scale =  _phase_progress + 0.8
			swoop_sound.play()
			_phase_cycles += 1
		if move_mode == MoveMode.SWOOP:
			_swoop_progress += delta * (_phase_progress + 0.6)
			if _swoop_progress >= 1.0:
				_swoop_progress = 0.0
				_delay = 2.0
				move_mode = MoveMode.FOLLOW
				particles(0.06)
				_phase_progress += 0.15
				attack_shape.disabled = true
				if _phase_cycles >= 6:
					_switch_phase()


func _shoot_bullet() -> void:
	var b := MenBullet.inst(
		global_position.direction_to(bullet_target.global_position + 0.5 * bullet_target.velocity), 80.0)
	bullet_home.add_child(b)
	b.global_position = global_position
	bullet_sound.play()


func _bombard_bullet() -> void:
	var b := MenBullet.inst(Vector2.DOWN.rotated(randf_range(-0.01, 0.01)), 80.0)
	bullet_home.add_child(b)
	b.global_position = global_position
	b.global_position.y += randf_range(-10, 10)
	b.global_position.x += randf_range(-160, 160)
	bullet_sound.play()


func _airstrike() -> void:
	var pos := bullet_target.global_position
	pos += _jitter() * randfn(2, 1)
	pos += bullet_target.velocity * 1.16
	var p := preload("res://scenes/vfx/vfx_x_attack_physical.tscn").instantiate()
	add_sibling(p)
	p.global_position = pos
	p.rotation = randf() * TAU


func _swoop_movement(progress: float, arc_len: float, arc_hi: float, start_pos: Vector2, direction: int) -> void:
	global_position.x = start_pos.x + progress * arc_len * direction
	global_position.y = start_pos.y + arc_hi * cos(progress * PI - PI / 2)


func _switch_phase() -> void:
	_phase_cycles = 0
	_delay = 3.0
	_phase_progress = 0
	phase = wrapi(phase + 1, Phase.NONE + 1, Phase.MAX) as Phase


func particles(amount: float = 0.0265) -> void:
	partic.amount_ratio = amount


func splode() -> void:
	plosive_particles.restart()


func go_light() -> void:
	light_display.show()
	dark_display.hide()


func go_dark() -> void:
	light_display.hide()
	dark_display.show()


func face_4() -> void: mdpsprite.animation = "4"
func face_big() -> void: mdpsprite.animation = "big"
func face_dark() -> void: mdpsprite.animation = "dark"
func face_default() -> void: mdpsprite.animation = "default"
func face_o() -> void: mdpsprite.animation = "o"
func face_smile() -> void: mdpsprite.animation = "smile"
func face_tilt() -> void: mdpsprite.animation = "tilt"
func face_worm() -> void: mdpsprite.animation = "worm"
func flip() -> void: mdpsprite.flip_h = not mdpsprite.flip_h

var tweener: Tween

func stopanim() -> void:
	if is_instance_valid(tweener) and tweener.is_valid(): tweener.kill()
	light_display.scale = Vector2.ONE
	mdpsprite.position = Vector2.ZERO
	mdpsprite.skew = 0.0


func bounce(speed: float) -> void:
	stopanim()
	tweener = create_tween().set_trans(Tween.TRANS_CUBIC).set_loops()
	tweener.tween_property(light_display, ^"scale:x", 1.1, 0.7 / speed)
	tweener.parallel().tween_property(light_display, ^"scale:y", 0.9, 0.8 / speed)
	tweener.tween_property(light_display, ^"scale:x", 0.9, 0.7 / speed)
	tweener.parallel().tween_property(light_display, ^"scale:y", 1.1, 0.8 / speed)


func shake() -> void:
	stopanim()
	tweener = create_tween().set_loops()
	tweener.tween_callback(func() -> void: mdpsprite.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	tweener.tween_interval(0.01)


func stretch() -> void:
	light_display.scale = Vector2(1.1, 0.9)


func sound_eep(): SND.play_sound(S_EEP)
func sound_heh(): SND.play_sound(S_HEH)
func sound_hmph(): SND.play_sound(S_HMPH)
func sound_eheh(): SND.play_sound(S_EHEH)
func sound_giggle() -> void: giggle_snd.play()
