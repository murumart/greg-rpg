extends Control

const POINTER_RANGE := Vector2i(3, 44)
const COMBO_MESSAGES:Array[String] = [
	"", "", "", "", "", "", "combo!", "combo!!", "comboer!!", "very combo!!!", "unbelievable!",
	"combo fantastique", "awesome", "harcore!", "delicious!", "incomparable!", "grand master combo!!!",
	"normal", "hard", "insane", "woaahhh", "wombo combo", "yeaaaahhhhhhh!!!!", "super duper combo!!",
	"combotastic!", "those who forget this combo...", "never before!!!", "never again!!!", "combo!!!",
	"it's a combo!", "i can't believe it's combo!", "i love combo!", "combination attack!", "uryaaaah!!!",
	"hey. you're pretty good at this skating business", "comboest combo!!!", "double donk!!", "unbelievable!!",
	"historical", "monster combo", "double combo!!!", "c", ":3", "galactic combo!", "planetary combo!",
	"meteorological combo!", "local weather system combo!", "local geological layer combo!", "clay combo!",
	"particle combo!", "molecular combo!", "atomic combo!", "electronic combo!", "super combo"
]

var points := 0
var displayed_points := 0
var combo := 0.0
var combo_hiscore := 0.0
var two_x_mode := false

@onready var balance_pointer: Sprite2D = $Panel/Balance/Pointer
@onready var boredom_pointer: Sprite2D = $Panel/Boredom/Pointer
@onready var points_label: Label = $Panel/Points/Label2
@onready var points_sound: AudioStreamPlayer = $Panel/Points/AudioStreamPlayer
@onready var points_tallied_sound: AudioStreamPlayer = $Panel/Points/AudioStreamPlayer2
@onready var combo_label: Label = $Panel/Combo/Label
@onready var jack_particles: GPUParticles2D = $"../JackParticles"


func _physics_process(delta: float) -> void:
	if displayed_points < points:
		displayed_points += maxi(floori((points - displayed_points) * 0.1), 1)
		points_label.text = str(displayed_points)
		points_tallied_sound.set_meta("played", false)
	points_sound.playing = displayed_points < points
	if points == displayed_points:
		if not points_tallied_sound.get_meta("played", false):
			points_tallied_sound.play()
			points_tallied_sound.set_meta("played", true)
	combo = maxf(combo - delta * sqrt(ceilf(combo) * 0.5), 0.0)
	if combo > combo_hiscore:
		combo_hiscore = combo
	combo_label.text = "combo " + str(maxi(ceili(combo), 1)) + "x"
	if two_x_mode:
		SOL.vfx_damage_number(Vector2(60, 10), "2x mode!!!", Color.RED, 1.5, {"parent": self, "speed": 4})


func display_balance(balance: float) -> void:
	balance_pointer.position.x = remap(balance, -1.0, 1.0, POINTER_RANGE.x, POINTER_RANGE.y)


func display_boredom(boredom: float) -> void:
	boredom_pointer.position.x = remap(maxf(boredom, 0.0), 0.0, 10.0, POINTER_RANGE.x, POINTER_RANGE.y)


func add_points(amt: int) -> void:
	if two_x_mode:
		amt *= 2
	else:
		if randf() < 0.01:
			two_x_mode = true
			var tw := create_tween()
			tw.tween_interval(4)
			tw.tween_callback(func():
				two_x_mode = false
			)
	points += roundi(amt * (combo + 1))
	if amt > 10:
		combo += 1
		if combo != 0 and ceili(combo) % 10 == 0:
			SND.play_sound(preload("res://sounds/skating/s7.ogg"))
			if combo >= 20:
				SOL.vfx("explosion", Vector2(53, 0))
		SOL.vfx_damage_number(Vector2(53, 0), COMBO_MESSAGES[ceili(combo)],
				Color.from_hsv(wrapf(ceilf(combo) * 0.08, 0.0, 1.0), 0.8, 1.0), 1.5)
	if amt > 200:
		if not jack_particles.emitting:
			var tw := create_tween()
			tw.tween_callback(jack_particles.set_emitting.bind(true))
			tw.tween_interval(5)
			tw.tween_callback(jack_particles.set_emitting.bind(false))
