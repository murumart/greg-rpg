extends Node2D

signal enemy_requested(e, String)

const DishType := preload("res://scenes/characters/battle_enemies/scn_enemy_dish.gd")

var beam_direction := 1.0
var initial_message_spoken := false
var skip_intro := false

@export var spin_speed := 155

@onready var beam := $Lighthouse/Beam as Sprite2D
@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var spin_pivot: Node2D = $Lighthouse/SpinPivot
@onready var mist_2: GPUParticles2D = $Mist2
@onready var mist: GPUParticles2D = $Mist
@onready var text_box: TextBox = $TextBox
@onready var zoom_animation: AnimationPlayer = $Lighthouse/ZoomAnimation


func _ready() -> void:
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 3.0)
	SOL.dialogue_box.started_speaking.connect(new_line)
	if not skip_intro:
		SOL.dialogue_open = true
		SOL.dialogue("president_start")
		hide_ui()
		mist.modulate.a = 0.0
		mist_2.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mist, "modulate:a", 1.0, 6.0)
		tw.parallel().tween_property(mist_2, "modulate:a", 1.0, 6.0)
		tw.tween_interval(5)
		tw.tween_property(beam, "modulate:a", 1.0, 0.6)


func _physics_process(delta: float) -> void:
	beam.scale.x += delta * spin_speed * (1 / 60.0) * beam_direction
	if beam.scale.x >= 2.0 or beam.scale.x <= -2.0:
		beam_direction *= -1
	beam.self_modulate.a = remap(absf(beam.scale.x), 0.0, 2.0, 0.1, 1.1)
	spin_pivot.rotation += spin_speed * delta * (1 / 60.0)
	spin_pivot.get_children().map(func(a: OverworldCharacter):
		a.global_rotation = 0.0
		a.direct_walking_animation(a.global_position.direction_to(spin_pivot.global_position))
	)


func show_ui() -> void:
	if LTS.get_current_scene().name == "Battle":
		create_tween().tween_property(
				LTS.get_current_scene().ui, "modulate:a", 1.0, 1.0
						).set_trans(Tween.TRANS_BOUNCE)


func hide_ui() -> void:
	if LTS.get_current_scene().name == "Battle":
		LTS.get_current_scene().ui.modulate.a = 0.0


func new_line(line: int) -> void:
	var tw : Tween
	if not initial_message_spoken and not skip_intro:
		if line == 3:
			tw = create_tween()
			tw.tween_property(spin_pivot, "modulate:a", 1.0, 2.0)
		elif line == 4:
			tw = create_tween()
			tw.tween_callback(lighthouse_zoom_in)
			tw.tween_callback(show_ui)
		elif line == 5:
			tw = create_tween()
			tw.tween_property(spin_pivot, "modulate:a", 0.0, 2.0)
		elif line == 6:
			text_box.text = ""
			initial_message_spoken = true
			SOL.dialogue_box.started_speaking.disconnect(new_line)


func dish_time(dish: DishType) -> void:
	hide_ui()
	lighthouse_zoom_out()
	SOL.dialogue_open = true
	var tw := create_tween()
	tw.parallel().tween_property(dish, "modulate:a", 0.0, 2.0).from(0.0)
	tw.parallel().tween_property(
			SND.current_song_player, "pitch_scale",
			2.0, 2.0)
	SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 1.9)
	tw.finished.connect(func():
		SND.play_song("", 2992)
		SND.play_song("dishout", 0.2)
		var t := create_tween()
		t.tween_property(
				SND.current_song_player,
				"pitch_scale",
				1.0,
				6.0
		).from(0.5)
		t.parallel().tween_property(dish, "modulate:a", 1.0, 3.0)
		SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 6.0)
		t.tween_interval(2.0).finished.connect(show_ui)
	)


func lighthouse_zoom_in() -> void:
	zoom_animation.play("zoom_in")


func lighthouse_zoom_out() -> void:
	zoom_animation.play_backwards("zoom_in")
