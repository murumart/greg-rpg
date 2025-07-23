class_name ListeningGame extends Node

signal finished(corrects: int)

const LISTENING_GAME = preload("res://scenes/minigame/listening/listening_game.tscn")
const NRSOUNDS := [
	preload("res://sounds/gui/zero.ogg"),
	preload("res://sounds/gui/one.ogg"),
	preload("res://sounds/gui/two.ogg"),
	preload("res://sounds/gui/three.ogg"),
	preload("res://sounds/gui/four.ogg"),
	preload("res://sounds/gui/five.ogg"),
	preload("res://sounds/gui/six.ogg"),
	preload("res://sounds/gui/seven.ogg"),
	preload("res://sounds/gui/eight.ogg"),
	preload("res://sounds/gui/nine.ogg"),
]

const CHANNELS := [
	{
		K.STREAM: preload("res://music/mus_bmsloop.ogg"),
		K.WEIGHT: 2,
	},
	{
		K.STREAM: preload("res://sounds/walking/bye.ogg"),
		K.WEIGHT: 2,
	},
	{
		K.STREAM: preload("res://music/mus_entrance_of_the_gladiators.ogg"),
		K.WEIGHT: 1,
	},
	{
		K.STREAM: preload("res://music/mus_mayor_boss.ogg"),
		K.WEIGHT: 12,
	},
	{
		K.STREAM: preload("res://music/mus_extremophile.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_police.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_fishing_game.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_forestguy.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_dishout.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_lion.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_birds.ogg"),
		K.WEIGHT: 4,
	},
]

enum Phases {
	START,
	SEARCH,
	PIN,
}

enum K {
	STREAM,
	WEIGHT,
}

@onready var noise_player: AudioStreamPlayer = $Noise
@onready var pointer: Sprite2D = $Pointer
@onready var panel_container: PanelContainer = $PanelContainer
@onready var progress_bar_container: VBoxContainer = %ProgressBarContainer
@onready var draw_panel: Panel = %DrawPanel
@onready var record_indicator: Sprite2D = %RecordIndicator
@onready var background_image: TextureRect = $PanelContainer/BackgroundImage

@export var volume_curve: Curve
@export var default_signal_noise: FastNoiseLite

var phase: Phases = Phases.START

var signal_sources: Array[AudioStreamPlayer]
var signal_noises: Array[FastNoiseLite]
var signal_scores: PackedFloat32Array
var signal_channels: PackedInt32Array
var signal_colors: PackedColorArray
var source_count := 3
var time := 0.0
var difficulty := 3.0
var tutorialate := false


static func make(diff: float, sources: int) -> ListeningGame:
	var lg: ListeningGame = LISTENING_GAME.instantiate()
	lg.difficulty = diff
	lg.source_count = sources
	lg.modulate.a = 0.0
	return lg


func _ready() -> void:
	_setup()
	var tw := create_tween()
	tw.tween_property(self, ^"modulate:a", 1.0, 2.0)
	if tutorialate:
		SOL.dialogue("mafia_tutorial_1")
		await SOL.dialogue_closed
	play()
	#pin(1)
	draw_panel.draw.connect(_dp_draw)


func _dp_draw() -> void:
	for i in source_count:
		var c := signal_colors[i]
		for x in panel_container.size.x:
			var n := _get_score(i, x)**8
			var dist := remap(absf(x - pointer.global_position.x), 0, 160, 0, 1.0)
			if int(x) % 2 == 0:
				continue
			draw_panel.draw_line(
				Vector2(draw_panel.position.x + x, draw_panel.position.y + 2),
				Vector2(draw_panel.position.x + x, draw_panel.position.y - n * draw_panel.size.y),
				Color(c, n - dist*4), -1, false)


func _display_reset() -> void:
	progress_bar_container.scale.y = 1.0
	record_indicator.modulate = Color.DARK_SLATE_GRAY



func _setup() -> void:
	for src in source_count:
		_add_signal_source()
		#SOL.make_display_label(self, func() -> String: return "score" + str(src) + ":" + str(_get_score(src)))
	print(signal_channels)


func _physics_process(delta: float) -> void:
	if phase == Phases.SEARCH:
		time += delta
		for n in signal_noises:
			n.offset.x += delta * 3.0
			n.offset.y += delta

		var inp := Input.get_axis(&"move_left", &"move_right")
		if inp:
			pointer.global_position.x = clampf(
				pointer.global_position.x + inp * 60.0 * delta,
				panel_container.position.x,
				panel_container.position.x + panel_container.size.x)
			noise_player.seek(randf() * noise_player.stream.get_length())

		var totvol := 0.0
		for i in source_count:
			signal_scores[i] = maxf(signal_scores[i] - delta * 0.051 * difficulty, 0.0)
			var score := _get_score(i, pointer.global_position.x)
			var vol := volume_curve.sample(score)
			var pp := (progress_bar_container.get_child(i) as ProgressBar)

			var old_score := signal_scores[i]
			if vol >= -6:
				signal_scores[i] += remap(vol, -6, 8, 0.0001, 1.0) * delta * remap(difficulty, 1.0, 10.0, 0.5, 0.1)

			signal_sources[i].volume_db = vol
			totvol += vol

			pp.value = signal_scores[i]
			pp.modulate = Color.GRAY
			if old_score < signal_scores[i]:
				pp.modulate = Color.SEA_GREEN

			if signal_scores[i] >= 1.0:
				pin(i)
		noise_player.volume_db = remap(clampf(totvol, -80, 8), -80, 8, 8.0, -20.0)
		draw_panel.queue_redraw()


func play() -> void:
	_display_reset()
	noise_player.play()
	phase = Phases.SEARCH


func pin(winner: int) -> void:
	phase = Phases.PIN
	await _pin_vis(winner)
	if tutorialate:
		SOL.dialogue("mafia_tutorial_2")
		await SOL.dialogue_closed
	await Math.timer(1.0)

	var corrects := 0
	for __ in 3:
		var correct := ""
		var leng := int(difficulty) + 1
		for x in leng:
			var number := randi_range(0, 9)
			SOL.vfx("damage_number", Vector2(randf_range(0, 160), randf_range(0, 120)), {text = str(number), parent = self})
			SND.play_sound(NRSOUNDS[number], {pitch_scale = 1.0 + difficulty * 0.05 + randf() * 0.05})
			correct += str(number)
			await Math.timer(clampf(1.0 - difficulty * 0.12, 0.01, 1.0) + randf() * 0.11115)
		var options := [correct]
		if correct.length() == 1:
			while options.size() != 3:
				var r := str(randi_range(0, 9))
				if r != correct:
					options.append(r)
		elif correct.length() == 2:
			while options.size() != 3:
				var o := correct
				o[randi_range(0, 1)] = str(randi_range(0, 9))
				if o != correct:
					options.append(o)
		else:
			while options.size() != 3:
				var c := Array(correct.split())
				c.shuffle()
				var d := "".join(c)
				if d != correct:
					options.append(d)
		options.shuffle()
		var dlg := DialogueBuilder.new()
		dlg.add_line(dlg.ml("...").schoices(options))
		var choice := await dlg.speak_choice()
		dlg.reset()
		if choice == correct:
			corrects += 1
		dlg.add_line(dlg.ml("you write down %s." % choice))
		await dlg.speak_choice()
	noise_player.stop()
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	record_indicator.modulate = Color.DARK_SLATE_GRAY
	await Math.timer(1.0)
	fin(corrects)


func _pin_vis(winner: int) -> void:
	var tw := create_tween()
	tw.tween_property(noise_player, ^"volume_db", 1.0, 2.0)
	tw.parallel().tween_property(noise_player, ^"pitch_scale", 1.0, 1.43)
	for i in source_count:
		if i != winner:
			tw.parallel().tween_property(signal_sources[i], ^"volume_linear", 0.0, 1.44)
			tw.parallel().tween_property(signal_sources[i], ^"pitch_scale", 0.1, 1.44)
		else:
			tw.parallel().tween_property(signal_sources[i], ^"volume_linear", 0.75, 1.44)
			tw.parallel().tween_property(signal_sources[i], ^"pitch_scale", clampf(signal_sources[i].pitch_scale, 0.88, 2.0), 0.75)
	tw.parallel().tween_property(progress_bar_container, ^"scale:y", 0.0, 1.44)
	tw.parallel().tween_property(pointer, ^"self_modulate:a", 0.0, 1.44)
	tw.parallel().tween_property(background_image, ^"self_modulate:a", 0.3, 1.44)
	tw.parallel().tween_property(draw_panel, ^"self_modulate:a", 0.0, 1.44)
	tw.tween_property(signal_sources[winner], ^"volume_linear", 0.0, 1.44)
	tw.parallel().tween_property(signal_sources[winner], ^"pitch_scale", 0.1, 1.44)
	tw.tween_callback(func() -> void:
		record_indicator.modulate = Color.WHITE
		SND.play_sound(preload("res://sounds/skating/s1.ogg"), {bus = &"Radio Music", volume = 14})
	)
	await tw.finished


func fin(corrects: int) -> void:
	print("you win ", corrects)
	finished.emit(corrects)


func _add_signal_source() -> void:
	signal_scores.append(0.0)

	var s := AudioStreamPlayer.new()
	signal_sources.append(s)
	var src: Dictionary = Math.weighted_random(CHANNELS, CHANNELS.map(func(a: Dictionary) -> int: return a.get(K.WEIGHT, 5)))
	signal_channels.append(CHANNELS.find(src))
	s.stream = src[K.STREAM]
	s.bus = &"Radio Music"
	add_child(s)
	s.pitch_scale = clampf(randfn(1.2, 4.0), 0.9, 8.0)
	s.volume_db = -80.0
	s.play()

	var n := default_signal_noise.duplicate()
	n.seed = randi()
	n.frequency = clampf(randfn(0.02, 0.01), 0.002, 0.045) * difficulty * 0.5
	signal_noises.append(n)

	var pp := ProgressBar.new()
	pp.max_value = 1.0
	pp.min_value = 0.0
	pp.step = 0.001
	progress_bar_container.add_child(pp)

	signal_colors.append(Color(randf(), randf(), randf()).lightened(0.33))


func _get_score(i: int, x: float) -> float:
	var wait_time_1 := 1.0
	var wait_time_2 := 4.0
	var n := signal_noises[i]
	var score := n.get_noise_2d(x, 0)
	if time < wait_time_1:
		return 0.0
	elif time < wait_time_2:
		return score * remap(time, wait_time_1, wait_time_2, 0.0, 1.0)
	return score
