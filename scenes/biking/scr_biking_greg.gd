extends Node2D

# biking player

signal health_changed(to: float)
signal died

var speed := 200
var moving_speed := 60.0
var paused := false

var max_health := 100
var health := 100
var hits := 0

@onready var nodes := $Greg
@onready var wheels := [$Lwheel, $Rwheel]

@onready var pedal_animator := $Greg/PedalingAnimation
@onready var animation_tree := $Greg/AnimationTree
@onready var peas := $Greg/Head/Peas
@onready var mail_sprite := $Greg/Rarm/MailSprite
@onready var paper_throw_audio := $Greg/Rarm/PaperThrowAudio
@onready var head_sprite := $Greg/Head/Head

@onready var invincibility_timer := $InvincibilityTimer

@onready var collision_area := $CollisionArea

const MAIL_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_mail.tscn")
enum MailModes {NORMAL, FOLLOW, SAUCE, SUPER}
var mail_mode := MailModes.NORMAL

var effects := {}

const HURT_SOUND := preload("res://sounds/biking_tumble.ogg")
const CRASH_SOUND := preload("res://sounds/biking_crash.ogg")


func _ready() -> void:
	set_ragdoll_enabled(false)
	animation_tree.active = true
	max_health = roundi(ResMan.get_character("greg").max_health)
	health = max_health


var rbpx := BikingGame.ROAD_BOUNDARIES.position.x
var rbsx := BikingGame.ROAD_BOUNDARIES.size.x
var rbpy := BikingGame.ROAD_BOUNDARIES.position.y
var rbsy := BikingGame.ROAD_BOUNDARIES.size.y
var fire_held := 0.0
func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if health <= 0.0 or paused: input = Vector2.ZERO
	# movement clamped to the road
	global_position += Vector2(input) * moving_speed * delta
	global_position.x = clampf(global_position.x, rbpx, rbsx)
	global_position.y = clampf(global_position.y, rbsy + 4, rbpy - 3)
	animation_tree["parameters/pedaling_speed/scale"] = (speed * delta) + input.x
	# https://cdn.discordapp.com/attachments/1065785853017862144/1101131203689586782/gregexplains_wheels.png for explanation
	for w in wheels:
		w.rotation = w.rotation + (speed * delta * 0.25 * (Vector2(input.x + float(not paused), input.y).length() if not (global_position.x >= rbsx or global_position.x <= rbpx) else 1.0))

	if speed > 0 and not paused:
		if Input.is_action_pressed("ui_accept"):
			if mail_mode == MailModes.SUPER:
				lob(2.0)
			else:
				fire_held = clampf(fire_held + delta, 1.0, 3.0)
			lob_in()
		if Input.is_action_just_released("ui_accept"):
			lob(fire_held)
			fire_held = 0.0
	# what
	if Input.is_action_pressed("ui_text_backspace"):
		head_sprite.region_rect.position.y = 10.0
	if Input.is_action_just_released("ui_text_backspace"):
		head_sprite.region_rect.position.y = 0.0

	# do stuff but only sometimes
	if Engine.get_physics_frames() % 16 == 0:
		for e in effects.keys():
			if e == "coin_magnet":
				get_tree().set_group("biking_coins", "following", true)

			# reduce effect durations
			var effect: Dictionary = effects[e]
			var time: float = effect.get("time", 0.0)
			time = max(time - delta * 16, 0.0) if speed > 5 else time
			effect["time"] = time
			if time <= 0:
				effects.erase(e)

	nodes.modulate.a = 1 - (int(invincibility_timer.time_left > 0.0) * 0.5)


# (lego crumble sound)
func set_ragdoll_enabled(to: bool) -> void:
	for node in nodes.get_children():
		if node is PhysicsBody2D:
			node.set_deferred("freeze", !to)
	if !to:
		pedal_animator.play("pedaling")
		animation_tree.active = true
	else:
		pedal_animator.stop()
		animation_tree.active = false


# fling em
func add_ragdoll_force(force: Vector2) -> void:
	for node in nodes.get_children():
		if node is RigidBody2D:
			node.apply_impulse(force + Vector2((randf_range(10, 20)), randf_range(-10, -20)))


func launch_ragdoll() -> void:
	set_ragdoll_enabled(true)
	call_deferred("add_ragdoll_force", Vector2(50, -150))


func heal(amount: int) -> void:
	health = clamp(health + absi(amount), 0, max_health)
	health_changed.emit(health)
	SOL.vfx_damage_number(head_sprite.global_position - Vector2(SOL.SCREEN_SIZE / 2), str(absi(amount)), Color.GREEN)


func hurt(amount: int) -> void:
	health = clamp(health - absi(amount), 0, max_health)
	if health <= 0:
		die()
		if amount >= 41:
			DAT.death_reason = "snail_beam"
		SND.play_sound(CRASH_SOUND)
	else:
		SND.play_sound(HURT_SOUND)
	health_changed.emit(health)
	hits += 1
	peas.emitting = true
	peas.set_deferred("emitting", false)
	SOL.vfx_damage_number(head_sprite.global_position - Vector2(SOL.SCREEN_SIZE / 2), str(absi(amount)), Color.RED)


func die() -> void:
	collision_area.set_deferred("monitoring", false)
	collision_area.set_deferred("monitorable", false)
	died.emit()
	launch_ragdoll()


func _on_collision_area_area_entered(area: Area2D) -> void:
	if not area.get_parent() is BikingObstacle: return
	var obstacle: BikingObstacle = area.get_parent()
	if invincibility_timer.time_left == 0.0:
		hurt(obstacle.damage)
		invincibility_timer.start(1.0)


func lob_in() -> void:
	var req := AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	var abor := AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	if not animation_tree.get("parameters/play_lob_in/active"):
		animation_tree.set("parameters/play_lob_in/request", req)
	if animation_tree.get("parameters/play_lob/active"):
		animation_tree.set("parameters/play_lob/request", abor)


# controls lobbing animation
func lob(speede: float) -> void:
	var req := AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	var abor := AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	var spd := func set_lob_speed(to: float) -> void:
		animation_tree.set("parameters/lobbing_speed/scale", to)
	mail_speed = speede
	animation_tree.set("parameters/play_lob_in/request", abor)
	if mail_mode == MailModes.SUPER: # cool secret perk activated
		spd.call(2.0) # speed faster
		if animation_tree.get("parameters/play_lob/active") == true:
			mail_speed = randf_range(1.0, 3.0)
			throw_mail() # throw if the animation is active
		animation_tree.set("parameters/play_lob/request", req) # if it isn't make it active
		return
	# normal throwing
	spd.call(1.0)
	if animation_tree.get("parameters/play_lob/active") == true:
		animation_tree.set("parameters/play_lob/request", abor) # cancel animation if  active
	else:
		# start animation if active
		animation_tree.set("parameters/play_lob/request", req)


# this is called from the animation
var mail_speed := 0.0
func throw_mail() -> void:
	var mail := MAIL_LOAD.instantiate()
	LTS.get_current_scene().add_child(mail)
	mail.global_position = mail_sprite.global_position
	mail.apply_impulse(Vector2(100 * mail_speed, -100 * mail_speed)) # whee
	mail.following = mail_mode == MailModes.FOLLOW
	paper_throw_audio.pitch_scale = randf_range(1.0, 1.2) * (
			(int(mail_mode == MailModes.SUPER) * 1.3) + 1)
	if mail_mode == MailModes.SAUCE:
		mail.set_saucy()
		paper_throw_audio.pitch_scale *= 0.89
	paper_throw_audio.play()
