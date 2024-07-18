extends Node2D

@onready var grandma: OverworldCharacter = $"../Grandma"
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var cats: Node2D = $"../Cats"
@onready var background: Sprite2D = $"../Background"
@onready var greg_pos: Marker2D = $GregPos
@onready var grandma_start_pos: Marker2D = $GrandmaStartPos
@onready var radio: Node2D = $"../Radio"
@onready var camera_final_pos: Marker2D = $CameraFinalPos
@onready var background_gradient := (($"../Background".material as
		ShaderMaterial).get_shader_parameter("Gradient") as GradientTexture1D).gradient
@onready var labels := Math.child_dict($TextBoxes)
@onready var grandma_voice: AudioStreamPlayer = $GrandmaVoice
@onready var grandma_glow: AnimatedSprite2D = $"../Grandma/GrandmaGlow"
@onready var canvas_modulate: ColorContainer = $"../CanvasModulateGroup/CutsceneColor"


func _ready() -> void:
	if DAT.get_data("fought_grandma", false) and not DAT.get_data("intro_cutscene_over", false):
		start()
	else:
		queue_free()


func start() -> void:
	show()
	canvas_modulate.color = Color(0.58039218187332, 0.45098039507866, 0.24705882370472)
	radio.queue_free()
	greg.direct_animation()
	SND.call_deferred("play_song", "grandma_scary")
	cats.queue_free()
	DAT.capture_player("cutscene")
	(func(): greg.global_position = greg_pos.global_position).call_deferred()
	grandma.global_position = grandma_start_pos.global_position
	grandma.speed = 200
	grandma.time_moved_limit = 2500
	grandma.random_movement = false
	grandma.move_to(grandma_start_pos.global_position + Vector2(0, 45))
	grandma_glow.show()
	create_tween().tween_property(grandma_glow, "scale", Vector2(2, 2), 10)
	create_tween().tween_property(canvas_modulate, "color", Color(0.27865263819695, 0.3454495370388, 0.11286202818155), 10).set_trans(Tween.TRANS_CUBIC)
	(func():
		var t := create_tween()
		t.tween_interval(3)
		t.tween_callback(func(): grandma_voice.playing = true)
		t.tween_property(labels.label_1, "visible_ratio", 1.0, 1.2).from(0.0)
		t.tween_callback(func(): grandma_voice.playing = false)
		t.tween_interval(2)
		t.tween_callback(func(): grandma_voice.playing = true)
		t.tween_callback(func(): labels.label_1.text += "\ni actually expected\nsome sort of\nfight from you.")
		t.tween_interval(0.1)
		t.tween_callback(func(): grandma_voice.playing = false)
		t.tween_interval(6)
		t.tween_callback(func(): grandma_voice.playing = true)
		t.tween_callback(func(): labels.label_1.text = "\n\n\n you little...\n  man.")
		t.tween_property(labels.label_1, "visible_ratio", 1.0, 2.0).from(0.0)
		t.parallel().tween_property(grandma_voice, "pitch_scale", 0.66, 2.0)
		t.tween_callback(func(): grandma_voice.playing = false)
		t.parallel().tween_property(labels.label_1, "theme_override_constants/shadow_offset_x", 4, 4)
		t.tween_property(labels.label_1, "modulate:a", 0.0, 8)
		t.tween_interval(1)
		t.tween_callback(func():
			grandma_voice.playing = true
			grandma_voice.pitch_scale = 0.3
		)
		labels.label_89.text = labels.label_89.text % [DAT.GDUNG_LEVEL, DAT.GDUNG_LEVEL]
		t.tween_property(labels.label_89, "visible_ratio", 0.232, 3).from(0.0)
		t.tween_callback(func():
			grandma_voice.playing = false
			grandma_voice.pitch_scale = 0.66
		)
		t.tween_interval(1)
		t.tween_callback(func(): grandma_voice.playing = true)
		t.tween_property(labels.label_89, "visible_ratio", 1, 3).from(0.232)
		t.tween_callback(func(): grandma_voice.playing = false)
		t.parallel().tween_property(labels.label_89, "theme_override_constants/shadow_offset_x", 66, 4).from(0.0)
		t.tween_interval(1.2)
		t.tween_callback(func():
			labels.label_89.text = "YOU MIGHT STAND A CHANCE, THEN."
			SND.play_song("", 12318)
		)
		t.tween_property(labels.label_89, "visible_ratio", 1, 3).from(0.0)
		t.parallel().tween_property(labels.label_89, "theme_override_constants/shadow_offset_x", 999,
				44).from(66.0)
	).call()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "zoom", Vector2(2.5, 2.5), 14)
	tw.parallel().tween_method(func(a: Color):
		background_gradient.set_color(0, a),
		Color.BLACK, Color(0.68999999761581, 0.68999999761581, 0.68999999761581), 12
	)
	tw.parallel().tween_property(camera, "rotation_degrees", -35, 16)
	tw.tween_property(camera, "zoom", Vector2(0.1, 0.1), 6.5)
	tw.parallel().tween_method(func(a: Color):
		background_gradient.set_color(1, a),
		Color.BLACK, Color(0.7738408446312, 0.77384078502655, 0.77384078502655), 8
	)
	tw.parallel().tween_property(canvas_modulate, "color", Color.AZURE, 8)
	tw.parallel().tween_property(camera, "rotation_degrees", 10, 14)
	tw.parallel().tween_property(camera, "global_position", camera_final_pos.global_position, 18)
	tw.parallel().tween_property(camera, "limit_left", -1992199, 13)
	tw.parallel().tween_property(camera, "limit_top", -1992199, 13)
	tw.parallel().tween_property(camera, "limit_bottom", 1992199, 13)
	tw.parallel().tween_property(camera, "limit_right", 1992199, 13)
	tw.tween_property(canvas_modulate, "color", Color.WHITE, 8)
	tw.tween_interval(4)
	tw.tween_callback(func():
		get_tree().get_processed_tweens().map(func(tew: Tween): if tew.is_valid(): tw.kill())
		canvas_modulate.color = Color.WHITE
		print("done now?")
		camera.zoom = Vector2.ONE
		camera.position = Vector2(0, -25)
		camera.rotation = 0
		camera.ignore_rotation = true
		camera.limit_bottom = 80
		grandma.direct_walking_animation(Vector2.DOWN)
		grandma_glow.hide()
		background_gradient.set_color(0, Color.BLACK)
		background_gradient.set_color(1, Color.BLACK)
		$TextBoxes.queue_free()
		greg.rotation_degrees = 90
		SOL.dialogue("grandma_fight_end")
		SOL.dialogue_closed.connect(func():
			LTS.gate_id = &"greghouse_inside-outside"
			LTS.level_transition(LTS.ROOM_SCENE_PATH % "greg_house")
			DAT.set_data("intro_progress", 2)
			DAT.free_player("cutscene")
		, CONNECT_ONE_SHOT)
	)
