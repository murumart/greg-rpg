extends Node2D

const SpeechBuble = preload("res://scenes/gui/x_speech_buble.gd")

const MUSIC_SPEED := 0.89

@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var pulse_d: Sprite2D = $Greg/Camera/PulseD
@onready var greg: PlayerOverworld = $Greg
@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var grand: OverworldCharacter = $Decor/Grand
@onready var speech: SpeechBuble = $SpeechBuble
@onready var intensiivne: AnimationPlayer = $Intensiivne
@onready var menacing := $Menacing
@onready var camera: Camera2D = $Greg/Camera
@onready var shader_bg: ColorRect = $Greg/Camera/ColorRect


func _ready() -> void:
	#SOL.dialogue_box.modulate = Color(0.851, 0.702, 0.478, 1.0)
	print(speech)
	mus_bar_counter.new_beat.connect(func() -> void:
		var tw := create_tween().set_trans(Tween.TRANS_BOUNCE)
		tw.set_ease(Tween.EASE_OUT).tween_property(pulse_d, ^"scale", Vector2.ONE, 0.4)
		tw.set_ease(Tween.EASE_IN).tween_property(pulse_d, ^"scale", Vector2.ONE * 0.98, 0.02)
	)
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 2.0, {kill_rects = true})
	grand.inspected.connect(_g_statue_interact)
	for n: Sprite2D in get_tree().get_nodes_in_group("stonepeople_sprites"):
		n.region_rect.position.x = randi_range(0, 3) * 16
		n.region_rect.position.y = randi_range(0, 3) * 16
	for n: OverworldCharacter in get_tree().get_nodes_in_group("stonepeople"):
		n.inspected.connect(func() -> void:
			var dlg := DialogueBuilder.new().set_char("column_talk")
			dlg.al(dlg.SGD + "[center]" + [
				"remembering",
				"storing",
				"saving",
				"waiting",
				"eagerly",
				"reminiscing",
				"reproduction",
				"copy",
				"right where we left off",
				"ready",
			].pick_random())
			dlg.speak_choice()
		)


func _g_statue_interact() -> void:
	DAT.capture_player("cutscene")
	var t := create_tween()
	var moveto := Vector2(grand.global_position.x - 16, grand.global_position.y)
	t.tween_property(greg, ^"global_position", moveto, 0.05 * moveto.distance_to(greg.global_position) * _debug_time_mul)
	t.tween_callback(greg.animate.bind("walk_right"))
	await t.finished
	var dlg := DialogueBuilder.new().set_char("silent")
	dlg.al(dlg.SGD + "There once was a little gardener.")
	dlg.al(dlg.SGD + "Though she loved gardening, she never could stay still.")
	dlg.al(dlg.SGD + "Anywhere a task required patience, she had not enough.")
	dlg.al(dlg.SGD + "One day, she was asked to take care of a large garden.")
	dlg.al(dlg.SGD + "She was told to just keep it as it is.")
	dlg.al(dlg.SGD + "The garden didn't look too nice, she thought...")
	dlg.al(dlg.SGD + "Overgrown in places, burned in others,")
	dlg.al(dlg.SGD + "and harboring a disease that would, every now and then")
	dlg.al(dlg.SGD + "wipe the garden of its life.")
	dlg.al(dlg.SGD + "Who wouldn't try to improve things?")
	dlg.al(dlg.SGD + "What could one do there, then...")
	dlg.al(dlg.SGD + "medicine... culling the rot... introducing new species...")
	dlg.al(dlg.SGD + "All good ideas the little gardener implements...")
	dlg.al(dlg.SGD + "...forgetting to see them through.")
	await dlg.speak_choice()
	greg.animate(greg.sprite.animation, false, 0.0)
	music.stop()
	SOL.vfx("xtarget", grand.global_position, {parent = grand})
	await Math.timer(1.75)
	intensiivne.play(&"def", -1, 1.0 / _debug_time_mul)
	SND.play_song_from_beginning("bymssc", 0.1)
	mus_bar_counter.reset()
	mus_bar_counter.bpm = 89.0
	await intensiivne.animation_finished
	_cs_2()


var _debug_time_mul := 0.0001

var _smoothp := Vector2()
func _pos_at_men() -> void:
	_smoothp = menacing.global_position - camera.global_position + SOL.SCREEN_CENTER
	speech.repos(_smoothp)
	menacing.modulate.a = minf(1.0, menacing.modulate.a + 0.07)


func _cs_2() -> void:
	var tw := create_tween()
	var cb := _pos_at_men
	tw.tween_property(menacing, "modulate:a", 0.07, 0.75 * _debug_time_mul)
	tw.tween_interval(0.15 * _debug_time_mul)
	var dlg := DialogueBuilder.new()
	dlg.al("little forgetful florist").scallback(cb)
	dlg.al("did i forget who i am too?").scallback(cb)
	dlg.al("it's embarrassing.").scallback(cb)
	dlg.al("i get so into my little persona").scallback(cb)
	dlg.al("...").scallback(cb)
	tw.tween_callback(func() -> void:
		speech.exhibit()
		await speech.speak(dlg.get_dial())
		_cs_3()
	)


func _cs_3() -> void:
	SND.play_song("", 0.6)
	menacing.move_mode = menacing.MoveMode.STOP
	menacing.move_target = null
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.0 * _debug_time_mul)
	tw.tween_property(menacing, "global_position", grand.global_position + Vector2(4, -8), 1.3 * _debug_time_mul)
	tw.parallel().tween_property(camera, ^"global_position", greg.global_position + Vector2(8, 10), 1.0 * _debug_time_mul)
	tw.parallel().tween_method(menacing.particles, 0.0, 1.0, 0.8 * _debug_time_mul)
	await tw.finished
	var dlg := DialogueBuilder.new()
	dlg.al("you destroyed the flower holders").scallback(_pos_at_men)
	dlg.al("and you destroyed the florist.").scallback(_pos_at_men)
	dlg.al("well done.").scallback(_pos_at_men)
	dlg.al("the least i can do now is to show you...").scallback(_pos_at_men)
	dlg.al("my true form.").scallback(_pos_at_men)
	await speech.speak(dlg.get_dial())
	await _go_intense(1.0, 4.0 * _debug_time_mul)
	menacing.go_light()
	menacing.modulate.a = 1.0
	await _go_reverse_intense(0.0, 0.01)
	menacing.sound_hmph()
	_cs_4.call_deferred()


func _cs_4() -> void:
	await Math.timer(1.0)
	const music_speed := 1.3
	const bpm := 130.0
	menacing.bounce(bpm * music_speed * (1.0 / 60.0) * 0.5)
	mus_bar_counter.reset()
	mus_bar_counter.bpm = bpm * music_speed * 0.5
	SND.play_song_from_beginning("beyond", 1.0, {start_volume = 0.0, pitch_scale = music_speed})
	_pos_at_men()
	speech.spam_sound = menacing.speech_snd
	var dlg := DialogueBuilder.new()
	dlg.al("lmao")
	await speech.speak(dlg.get_dial())


var bg_move_speed := 0.0


func _go_intense(to: float = 1.0, time := 1.0) -> void:
	DAT.capture_player("intense_move")
	greg.set_physics_process(false)
	var ints := $Intensiivne/AudioStreamPlayer
	ints.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(ints, ^"volume_linear", to, time).from(0.0)
	tw.parallel().tween_property(ints, ^"pitch_scale", to * 4.0 + 0.001, time)
	tw.parallel().tween_property(self, ^"bg_move_speed", to * 400.0, time)
	tw.parallel().tween_callback(SOL.fade_screen.bind(Color.TRANSPARENT, Color.WHITE, time * 0.5, {free_rect = false})).set_delay(time * 0.5)
	tw.tween_callback(func() -> void:
		DAT.free_player("intense_move")
		greg.set_physics_process(true)
		ints.stop()
	)
	await tw.finished


func _go_reverse_intense(to: float = 0.0, time := 1.0) -> void:
	assert(to >= 0.0)
	DAT.capture_player("intense_move")
	greg.set_physics_process(false)
	var ints := $Intensiivne/AudioStreamPlayer
	ints.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ints, ^"volume_linear", to, time).from(1.0)
	tw.parallel().tween_property(ints, ^"pitch_scale", to + 0.001, time)
	tw.parallel().tween_property(self, ^"bg_move_speed", to, time)
	tw.parallel().tween_callback(SOL.fade_screen.bind(Color.WHITE, Color.TRANSPARENT, time * 0.5, {kill_rects = true, free_rect = true}))
	tw.tween_callback(func() -> void:
		DAT.free_player("intense_move")
		greg.set_physics_process(true)
		ints.stop()
	)
	await tw.finished


func _process(delta: float) -> void:
	var dist := maxf(0, grand.global_position.x - greg.position.x)
	if dist < 300:
		var r := remap(dist, 300, 0, 1.0, 0.0)
		music.volume_linear = r
	if speech.box_readable and menacing.modulate.a > 0:
		_smoothp = _smoothp.move_toward(menacing.global_position - camera.global_position + SOL.SCREEN_CENTER, delta * 8.0)
		speech.repos(_smoothp, false, false)
	greg.global_position.x += bg_move_speed * delta
	menacing.global_position.x += bg_move_speed * delta
	var mat := (shader_bg.material as ShaderMaterial)
	var offset: float = mat.get_shader_parameter("offset").x + bg_move_speed * 0.05 * delta
	mat.set_shader_parameter("offset", Vector2(offset, offset))


func shakey() -> void:
	SOL.shake(0.2)
