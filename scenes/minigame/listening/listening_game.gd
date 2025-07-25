class_name ListeningGame extends Node2D

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

static var CHANNELS := [
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
		K.WEIGHT: 6,
		K.CUTSCENE: func() -> void:
		SND.play_song("forestguy", 0.46, {pitch_scale = 0.67, bus = "Radio Music"})
		var dlg := DialogueBuilder.new()
		await Math.timer(1.0)
		dlg.al("our path...")
		dlg.al("it can diverge and converge.")
		dlg.al("some walk the same path, hand in hand...")
		dlg.al("some walk the same path, stepping on each other's heels...")
		dlg.al("but their paths are so perfectly parallel to mine...")
		dlg.al("this is why i'm not fit for the [color=%s]flower.[/color]" % Math.FLOWERCOLOR)
		dlg.al("this is why she wants it back.")
		dlg.al("...")
		dlg.al("...but she can't face us herself.")
		dlg.al("we are futility.").stext_speed(0.4)
		dlg.al("walking the void path with her.").stext_speed(0.4)
		await dlg.speak_choice()
		SND.play_song("")
		,
	},
	{
		K.STREAM: preload("res://music/mus_dishout.ogg"),
		K.WEIGHT: 7,
	},
	{
		K.STREAM: preload("res://music/mus_lion.ogg"),
		K.WEIGHT: 6,
	},
	{
		K.STREAM: preload("res://music/mus_sweet_girls.ogg"),
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
	CUTSCENE,
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

var min_db := -25
var saw_cutscenes: PackedByteArray:
	set(to): DAT.set_data("saw_raido_cutscenes", to)
	get: return DAT.get_data("saw_raido_cutscenes", [])

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
	if not saw_cutscenes:
		saw_cutscenes = []
	_setup()
	var tw := create_tween()
	tw.tween_property(self, ^"modulate:a", 1.0, 2.0)
	if tutorialate:
		$GiveUpLabel.hide()
		SOL.dialogue_low_position()
		SOL.dialogue("mafia_tutorial_1")
		await SOL.dialogue_closed
	play()
	#pin(1)
	draw_panel.draw.connect(_dp_draw)


func _dp_draw() -> void:
	for i in source_count:
		var c := signal_colors[i]
		if signal_scores[i] >= 1.0:
			c = Color(c.darkened(0.75), 0.1)
		for x in panel_container.size.x:
			var sample_position := Vector2(to_global(Vector2(draw_panel.global_position.x + x, 0.0)).x, 0.0)
			var n := _get_score(i, sample_position.x)
			var dist := remap(absf(x - pointer.global_position.x), 0, 160, 0, 1.0)
			if int(x) % 2 == 0:
				continue
			var line_height := n ** 20 * draw_panel.size.y
			draw_panel.draw_line(
				Vector2(draw_panel.position.x + x, draw_panel.position.y + 2),
				Vector2(draw_panel.position.x + x, draw_panel.position.y - line_height),
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
	if (phase == Phases.SEARCH) and Input.is_action_just_pressed(&"cancel") and not tutorialate and not SOL.dialogue_open:
		SND.play_sound(preload("res://sounds/pennistong/pennistong_lose.ogg"))
		fin(0, "you gave up.", -1)
	if phase == Phases.SEARCH:
		time += delta
		for n in signal_noises:
			n.offset.x += delta * 3.0
			n.offset.y += delta

		var inp := Input.get_axis(&"move_left", &"move_right")
		if inp:
			pointer.global_position.x = clampf(
				pointer.global_position.x + inp * 60.0 * delta,
				panel_container.global_position.x,
				panel_container.global_position.x + panel_container.size.x)
			noise_player.seek(randf() * noise_player.stream.get_length())

		var totvol := 0.0
		var finisheds := 0
		for i in source_count:
			if signal_scores[i] >= 1.0:
				finisheds += 1
				signal_sources[i].volume_db = maxf(-80, signal_sources[i].volume_db - delta)
				if finisheds >= source_count:
					pin(i)
				continue
			var score := _get_score(i, pointer.global_position.x)
			if score <= 0:
				signal_scores[i] = maxf(signal_scores[i] - delta * 0.0251 * difficulty, 0.0)
			var vol := volume_curve.sample(score)
			var pp := (progress_bar_container.get_child(i) as ProgressBar)

			var old_score := signal_scores[i]
			if vol >= min_db:
				signal_scores[i] += remap(vol, min_db, 8, 0.00001, 1.0) * delta * remap(difficulty, 1.0, 10.0, 0.5, 0.1)

			signal_sources[i].volume_db = vol
			totvol += vol

			pp.value = signal_scores[i]
			pp.modulate = Color.GRAY
			if old_score < signal_scores[i]:
				pp.modulate = signal_colors[i].darkened(0.25)
				pp.modulate = signal_colors[i].darkened(0.25)

			if signal_scores[i] >= 1.0:
				finisheds += 1
				#if finisheds >= source_count:
					#pin(i)
		noise_player.volume_db = remap(clampf(totvol, -80, 8), -80, 8, 8.0, -20.0)
		draw_panel.queue_redraw()


func play() -> void:
	_display_reset()
	noise_player.play()
	phase = Phases.SEARCH


func pin(winner: int) -> void:
	phase = Phases.PIN
	$GiveUpLabel.hide()
	await _pin_vis(winner)
	if tutorialate:
		SOL.dialogue("mafia_tutorial_2")
		await SOL.dialogue_closed
	await Math.timer(1.0)

	var corrects := 0
	var finstring := ""
	for __ in 3:
		var correct := ""
		var leng := int(difficulty) + 1
		for x in leng:
			var number := randi_range(0, 9)
			SOL.vfx("damage_number", Vector2(randf_range(0, 160), randf_range(0, 120)), {text = str(number), parent = self})
			SND.play_sound(NRSOUNDS[number], {pitch_scale = 1.0 + difficulty * 0.05 + randf() * 0.05})
			correct += str(number)
			await Math.timer(clampf(1.0 - difficulty * 0.12, 0.1, 1.0) + randf() * 0.11115)
		var options := [correct]
		var opsize := int(remap(difficulty, 2, 10, 3, 6))
		if correct.length() == 1:
			while options.size() != opsize:
				var r := str(randi_range(0, 9))
				if r != correct:
					options.append(r)
		elif correct.length() == 2:
			while options.size() != opsize:
				var o := correct
				o[randi_range(0, 1)] = str(randi_range(0, 9))
				if o != correct:
					options.append(o)
		else:
			var tries := 0
			while options.size() != opsize:
				if tries < 100:
					var c := Array(correct.split())
					c.shuffle()
					var d := "".join(c)
					if d != correct:
						options.append(d)
				else:
					var s := ""
					for l in leng:
						s += str(randi_range(0, 9))
					if s != correct:
						options.append(s)
				tries += 1
		options.shuffle()
		var dlg := DialogueBuilder.new()
		dlg.add_line(dlg.ml("...").schoices(options))
		var choice := await dlg.speak_choice()
		dlg.reset()
		finstring += choice + "... "
		if choice == correct:
			corrects += 1
			finstring += "correct"
		else:
			finstring += "incorrect"
		finstring += "\n"
		dlg.add_line(dlg.ml("you write down %s." % choice))
		await dlg.speak_choice()
	noise_player.stop()
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	record_indicator.modulate = Color.DARK_SLATE_GRAY
	await Math.timer(1.0)
	fin(corrects, finstring, signal_channels[winner])


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


func fin(corrects: int, finstring: String, channel: int) -> void:
	phase = Phases.START
	var dlg := DialogueBuilder.new()
	dlg.al(finstring)
	await dlg.speak_choice()
	if corrects == 3 and K.CUTSCENE in CHANNELS[channel] and not channel in saw_cutscenes:
		await CHANNELS[channel][K.CUTSCENE].call()
		saw_cutscenes.append(channel)
		await Math.timer(1.0)
	var xp := corrects * 12.0 * difficulty
	ResMan.get_character("greg").add_experience(xp, true)
	await SOL.dialogue_closed
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
