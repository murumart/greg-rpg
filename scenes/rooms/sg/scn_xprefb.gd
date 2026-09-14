extends Node2D

const SpeechBuble = preload("res://scenes/gui/x_speech_buble.gd")
const Menacing = preload("res://scenes/vfx/x_menacing.gd")

const MUSIC_SPEED := 0.89

@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var pulse_d: Sprite2D = $Greg/Camera/PulseD
@onready var greg: PlayerOverworld = $Greg
@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var grand: OverworldCharacter = $Decor/Grand
@onready var speech: SpeechBuble = $SpeechBuble
@onready var intensiivne: AnimationPlayer = $Intensiivne
@onready var mdp: Menacing = $Menacing
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
	_smoothp = mdp.global_position - camera.global_position + SOL.SCREEN_CENTER
	speech.repos(_smoothp)
	mdp.modulate.a = minf(1.0, mdp.modulate.a + 0.07)


func _cs_2() -> void:
	var tw := create_tween()
	var cb := _pos_at_men
	tw.tween_property(mdp, "modulate:a", 0.07, 0.75 * _debug_time_mul)
	tw.tween_interval(0.15 * _debug_time_mul)
	var dlg := DialogueBuilder.new()
	dlg.al("it's embarrassing.").scallback(cb)
	dlg.al("i get so into my little persona").scallback(cb)
	dlg.al('"the little forgetful florist"').scallback(cb)
	dlg.al("...").scallback(cb)
	tw.tween_callback(func() -> void:
		speech.exhibit()
		await speech.speak(dlg.get_dial())
		_cs_3()
	)


func _cs_3() -> void:
	SND.play_song("", 0.6)
	mdp.move_mode = mdp.MoveMode.STOP
	mdp.move_target = null
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.0 * _debug_time_mul)
	tw.tween_property(mdp, "global_position", grand.global_position + Vector2(4, -8), 1.3 * _debug_time_mul)
	tw.parallel().tween_property(camera, ^"global_position", greg.global_position + Vector2(8, 10), 1.0 * _debug_time_mul)
	tw.parallel().tween_method(mdp.particles, 0.0, 1.0, 0.8 * _debug_time_mul)
	await tw.finished
	var dlg := DialogueBuilder.new()
	dlg.al("like you destroyed the flower holders").scallback(_pos_at_men)
	dlg.al("you also destroyed the florist.").scallback(_pos_at_men)
	dlg.al("what's left under is ME.").scallback(_pos_at_men)
	await speech.speak(dlg.get_dial())
	await _go_intense(1.0, 4.0 * _debug_time_mul)
	mdp.go_light()
	mdp.modulate.a = 1.0
	await _go_reverse_intense(0.0, 0.01)
	mdp.sound_hmph()
	_cs_4.call_deferred()


func _cs_4() -> void:
	await Math.timer(2.0)
	const music_speed := 1.3
	const bpm := 130.0
	mdp.bounce(bpm * music_speed * (1.0 / 60.0) * 0.5)
	mus_bar_counter.reset()
	mus_bar_counter.bpm = bpm * music_speed * 0.5
	SND.play_song_from_beginning("beyond", 1.0, {start_volume = 0.0, pitch_scale = music_speed})
	_pos_at_men()
	speech.spam_sound = mdp.speech_snd
	var dlg := DialogueBuilder.new()
	var tw: Tween
	dlg.al("hey.").scallback(mdp.sound_eheh)
	dlg.al("well done there")
	dlg.al("destroying my physis.").scallback(mdp.face_tilt)
	dlg.al("what a day huh... lots to unpack.").scallback(mdp.flip)
	dlg.al('you might be thinking: "what in the background noise are you?"').scallback(func() -> void:
		tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mdp, "position:x", mdp.position.x + 10, 1.0)
		mdp.face_handout()
	)
	dlg.al("so... there was no florist. it was just a front.").scallback(func() -> void:
		mdp.flip()
		mdp.face_smile()
	)
	dlg.al("after they took my hand and... pulled me out of the puddle that was my world...").scallback(func() -> void:
		mdp.flip()
		mdp.face_default()
	)
	dlg.al("and showed me the whole SEA...").scallback(mdp.face_o)
	dlg.al("i was immediately made to keep watch over yours.").scallback(mdp.face_worm)
	dlg.al("your awful! reeking! world!").scallback(func() -> void:
		mdp.flip()
		mdp.stopanim()
		mdp.shake_horiz()
	)
	dlg.al("and i could only look! not touch!").scallback(func() -> void:
		tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mdp, "position:x", mdp.position.x - 10, 1.0)
	)
	dlg.al("when my touch would change it for the BETTER!!").scallback(mdp.face_dark)
	dlg.al("...it didn't change for the better.")
	dlg.al("everyone i gave flowers just... moved... from their purpose.")
	dlg.al("if you prod an anthill, the ants go crazy...").scallback(mdp.face_tilt)
	dlg.al("they get violent. attack regardless of target.")
	dlg.al("until it rains.").scallback(mdp.flip)
	dlg.al("hey. greggy boy. my little droplet.").scallback(func() -> void:
		tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mdp, "position:x", mdp.position.x - 10, 1.0)
		mdp.face_smile()
		mdp.sound_giggle()
		mdp.bounce(bpm * music_speed * (1.0 / 60.0) * 0.5)
		mdp.flip()
	)
	dlg.al("i've caused myself so much trouble").scallback(mdp.face_handout)
	dlg.al("so thank you for freshening me up.").scallback(mdp.face_tilt)
	dlg.al("i think you've earned your house back.").scallback(func() -> void:
		mdp.flip()
		mdp.face_default()
	)
	dlg.al("let's go... ").scallback(func() -> void:
		tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mdp, "position:x", mdp.position.x + 10, 1.0)
		SND.play_song("")
	)
	await speech.speak(dlg.get_dial())
	await _go_intense(0.5, 2.0)
	mdp.face_fell()
	mdp.shake_horiz()
	mdp.sound_hmph()
	await _go_reverse_intense(0.0, 0.1)
	await Math.timer(2.0)
	mdp.face_lookdown()
	mdp.shake_horiz()
	await Math.timer(1,0)
	dlg.clear()
	dlg.al("let's go.")
	await speech.speak(dlg.get_dial())
	await _go_intense(1.0, 4.0)
	LTS.gate_id = &"afterexpo"
	LTS.change_scene_to("res://scenes/rooms/scn_room_grandma_house_inside.tscn")


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
	if speech.box_readable and mdp.modulate.a > 0:
		_smoothp = _smoothp.move_toward(mdp.global_position - camera.global_position + SOL.SCREEN_CENTER, delta * 8.0)
		speech.repos(_smoothp, false, false)
	greg.global_position.x += bg_move_speed * delta
	mdp.global_position.x += bg_move_speed * delta
	var mat := (shader_bg.material as ShaderMaterial)
	var offset: float = mat.get_shader_parameter("offset").x + bg_move_speed * 0.05 * delta
	mat.set_shader_parameter("offset", Vector2(offset, offset))


func shakey() -> void:
	SOL.shake(0.2)
