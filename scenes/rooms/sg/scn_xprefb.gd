extends Node2D

const SpeechBuble = preload("res://scenes/gui/x_speech_buble.gd")

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
	t.tween_property(camera, ^"global_position:x", floorf((greg.global_position.x + grand.global_position.x) * 0.5), 2.0)
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
	await Math.timer(2.0)
	intensiivne.play(&"def", -1, 100)
	SND.play_song("bymssc", 0.1)
	mus_bar_counter.reset_floats()
	mus_bar_counter.bpm = 89
	await intensiivne.animation_finished
	_cs_2()


var _smoothp := Vector2()
func _pos_at_men() -> void:
	_smoothp = menacing.global_position - camera.global_position + SOL.SCREEN_CENTER
	speech.repos(_smoothp)
	menacing.modulate.a += 0.07


func _cs_2() -> void:
	var tw := create_tween()
	var cb := _pos_at_men
	tw.tween_property(menacing, "modulate:a", 0.07, 2.0)
	tw.tween_callback(func() -> void:
		speech.exhibit()
	)
	tw.tween_interval(0.5)
	var dlg := DialogueBuilder.new()
	dlg.al("little forgetful gardener").scallback(cb)
	dlg.al("did i forget who i am too?").scallback(cb)
	dlg.al("it's embarrassing.").scallback(cb)
	dlg.al("i get so into my little persona").scallback(cb)
	dlg.al("...").scallback(cb)
	tw.tween_callback(func() -> void:
		await speech.speak(dlg.get_dial())
		_cs_3()
	)


func _cs_3() -> void:
	SND.play_song("", 0.6)
	menacing.move_mode = menacing.MoveMode.STOP
	menacing.move_target = null
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.0)
	tw.tween_property(menacing, "global_position", grand.global_position - Vector2(0, 8), 1.3)
	tw.parallel().tween_method(menacing.particles, 0.0, 1.0, 1.3)
	tw.parallel().tween_property(menacing, "modulate:a", 1.0, 1.3)
	await tw.finished
	var dlg := DialogueBuilder.new()
	dlg.al("let's see something.").scallback(_pos_at_men)
	await speech.speak(dlg.get_dial())
	var ints := $Intensiivne/AudioStreamPlayer
	ints.play()
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN).tween_property(shader_bg.material, "shader_parameter/offset:x", 15.0, 3.0)
	tw.parallel().tween_property(ints, "volume_db", 0.0, 3.0)
	tw.parallel().tween_property(ints, "pitch_scale", 0.66, 3.0)
	SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 3.0, {free_rect = false})
	tw.tween_callback(ints.stop)



func _process(delta: float) -> void:
	var dist := 1275 - greg.position.x
	if dist < 300:
		music.volume_linear = remap(dist, 300, 0, 1.0, 0.05)
	if speech.box_readable and menacing.modulate.a > 0:
		_smoothp = _smoothp.move_toward(menacing.global_position - camera.global_position + SOL.SCREEN_CENTER, delta * 4.0)
		speech.repos(_smoothp, false, false)


func shakey() -> void:
	SOL.shake(0.2)
