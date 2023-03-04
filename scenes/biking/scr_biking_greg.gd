extends Node2D

signal health_changed(to: float)
signal died

var speed := 200
var paused := false

var max_health := 100
var health := 100

@onready var nodes := $Greg
@onready var wheels := [$Lwheel, $Rwheel]

@onready var pedal_animator := $Greg/PedalingAnimation
@onready var animation_tree := $Greg/AnimationTree
@onready var peas := $Greg/Head/Peas
@onready var mail_sprite := $Greg/Rarm/MailSprite
@onready var paper_throw_audio := $Greg/Rarm/PaperThrowAudio
@onready var head_sprite := $Greg/Head/Head

const MAIL_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_mail.tscn")
var super_mail := false
var following_mail := false

const PAPER_SOUNDS := [
	preload("res://sounds/paper/paper4.ogg"),
]
const HURT_SOUND := preload("res://sounds/snd_biking_tumble.ogg")
const CRASH_SOUND := preload("res://sounds/snd_biking_crash.ogg")


func _ready() -> void:
	set_ragdoll_enabled(false)
	animation_tree.active = true
	max_health = roundi(DAT.get_character("greg").max_health)
	health = roundi(DAT.get_character("greg").health)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	global_position += Vector2(input) * speed * delta
	global_position.x = clampf(global_position.x, BikingGame.ROAD_BOUNDARIES.position.x, BikingGame.ROAD_BOUNDARIES.size.x)
	global_position.y = clampf(global_position.y, BikingGame.ROAD_BOUNDARIES.size.y, BikingGame.ROAD_BOUNDARIES.position.y)
	animation_tree["parameters/pedaling_speed/scale"] = (speed * delta) + input.x
	for w in wheels:
		w.rotation = w.rotation + (speed * delta * 0.25 * (Vector2(input.x + float(not paused), input.y).length() if not (global_position.x >= BikingGame.ROAD_BOUNDARIES.size.x or global_position.x <= BikingGame.ROAD_BOUNDARIES.position.x) else 1.0))
	
	if (Input.is_action_just_pressed("ui_accept") or
	(Input.is_action_pressed("ui_accept") and super_mail)):
		if speed > 0 and not paused:
			lob()
	if Input.is_action_pressed("ui_text_backspace"):
		head_sprite.region_rect.position.y = 10.0
	if Input.is_action_just_released("ui_text_backspace"):
		head_sprite.region_rect.position.y = 0.0


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


func hurt(amount: int) -> void:
	health = clamp(health - absi(amount), 0, max_health)
	if health <= 0:
		die()
		SND.play_sound(CRASH_SOUND)
	else:
		SND.play_sound(HURT_SOUND)
	health_changed.emit(health)
	peas.emitting = true
	peas.set_deferred("emitting", false)


func die() -> void:
	died.emit()
	launch_ragdoll()


func _on_collision_area_area_entered(area: Area2D) -> void:
	if not area.get_parent() is BikingObstacle: return
	var obstacle : BikingObstacle = area.get_parent()
	hurt(obstacle.damage)


func lob() -> void:
	if super_mail:
		animation_tree.set("parameters/lobbing_speed/scale", 2.0)
		if animation_tree.get("parameters/play_lob/active") == true:
			throw_mail()
		animation_tree.set("parameters/play_lob/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		return
	animation_tree.set("parameters/lobbing_speed/scale", 1.0)
	if animation_tree.get("parameters/play_lob/active") == true:
		animation_tree.set("parameters/play_lob/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	else:
		animation_tree.set("parameters/play_lob/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func throw_mail() -> void:
	var mail := MAIL_LOAD.instantiate()
	DAT.get_current_scene().add_child(mail)
	mail.global_position = mail_sprite.global_position
	mail.apply_impulse(Vector2(
		randf_range(100, 200),
		randf_range(-300, -100)
	))
	mail.following = following_mail
#	SND.play_sound(PAPER_SOUNDS.pick_random(), {"volume": -8, "pitch": randf_range(1.0, 1.2)})
	paper_throw_audio.pitch_scale = randf_range(1.0, 1.2) * ((int(super_mail) * 1.3) + 1)
	paper_throw_audio.play()

