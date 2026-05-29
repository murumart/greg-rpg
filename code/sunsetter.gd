class_name Sunsetter extends Node

const SUNSET_LEVEL := 72
const SUNSET_COLOR := Color(1.0, 0.651, 0.576)
const RAIN_COLOR := Color(0.78, 0.855, 0.929)
const SUNSET_TRIGGER_KEY := &"sunset_triggered"
const RAINING_KEY := &"raining"

@export var sky_modulate: ColorContainer
@export var rain_modulate: ColorContainer
@export var rain_particles: GPUParticles2D
@export var room: Room
@export var sunset_music := ""
@export var rainy_music := ""
@export var sunset_trigger_gates: Array[StringName]

static var is_raining: bool:
	get:
		return DAT.get_data(RAINING_KEY, false)
	set(to):
		DAT.set_data(RAINING_KEY, to)

var default_music := ""


func _ready() -> void:
	assert(rain_particles, "no rain particles assigned")
	var lvl := ResMan.get_character("greg").level
	var is_sunset := _sunset_triggered()
	if is_sunset or lvl >= SUNSET_LEVEL and _correct_gate():
		sky_modulate.color = SUNSET_COLOR
		if sunset_music and room:
			default_music = room.music
			room.music = sunset_music
		if not is_sunset:
			DAT.set_data(SUNSET_TRIGGER_KEY, true)
	elif is_raining:
		RenderingServer.global_shader_parameter_set(&"wind_strength", 0.02)
		rain_modulate.color = RAIN_COLOR
		if rainy_music and room:
			default_music = room.music
			room.music = rainy_music
		rain_particles.emitting = true


func _correct_gate() -> bool:
	return sunset_trigger_gates.is_empty() or LTS.gate_id in sunset_trigger_gates


func _sunset_triggered() -> bool:
	return DAT.get_data(SUNSET_TRIGGER_KEY, false)


func start_raining() -> void:
	RenderingServer.global_shader_parameter_set(&"wind_strength", 0.02)
	is_raining = true
	rain_particles.emitting = true
	rain_particles.amount_ratio = 0
	var tw := create_tween()
	tw.tween_property(rain_modulate, ^"color", RAIN_COLOR, 4.0).from(Color.WHITE)
	tw.parallel().tween_property(rain_particles, ^"amount_ratio", 1.0, 4.0).from(0.0)
	SND.play_song(rainy_music, 0.5)


func stop_raining() -> void:
	RenderingServer.global_shader_parameter_set(&"wind_strength", 0.01)
	is_raining = false
	var tw := create_tween()
	tw.tween_property(rain_modulate, ^"color", Color.WHITE, 4.0).from(RAIN_COLOR)
	tw.parallel().tween_property(rain_particles, ^"amount_ratio", 1.0, 4.0).from(0.0)
	tw.tween_callback(rain_particles.set_emitting.bind(false))
	SND.play_song(default_music, 0.5)
