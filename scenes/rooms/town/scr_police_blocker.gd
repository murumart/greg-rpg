extends Node2D

@onready var detect := $DetectionArea as Area2D

@onready var love_gradient: Sprite2D = $Love

@onready var popo: OverworldCharacter = $PopoRomantic
@onready var popo_sprite: AnimatedSprite2D = $PopoRomantic/Sprite
@onready var popo_sprite_s: AnimatedSprite2D = $PopoRomantic/Shadow
@export var greg: PlayerOverworld
@export var science_guy: OverworldCharacter
@export var room: Room

@onready var cars: Node2D = $Cars
@onready var cars_audio: AudioStreamPlayer2D = $Cars/AudioStreamPlayer2D
@onready var anim := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	var gregc := ResMan.get_character("greg")
	var has_rose := gregc.inventory.has("flower5")
	if DAT.get_data("popo_blockade_lifted", false):
		queue_free()
		return
	remove_child(love_gradient)
	SOL.add_ui_child(love_gradient)
	love_gradient.hide()
	if PoliceStation.should_be_at_blocker():
		popo.inspected.connect(_popo_interacted)
		if has_rose:
			$DetectionArea/CollisionShape2D2.disabled = false
			detect.body_entered.connect(_date_cutscene.unbind(1))
		else:
			detect.body_entered.connect(_body_entered.unbind(1))
			detect.body_exited.connect(_body_exited.unbind(1))
	else:
		popo.queue_free()
		detect.body_entered.connect(_body_entered.unbind(1))
		detect.body_exited.connect(_body_exited.unbind(1))


func _popo_interacted() -> void:
	pass

func _body_entered() -> void:
	anim.play("slide")


func _body_exited() -> void:
	anim.play_backwards("slide")


func _date_cutscene() -> void:
	CarOverworld.static_paused = true
	popo.can_be_run_over = true
	DAT.capture_player("cutscene")
	SND.play_song("")
	var tw := create_tween()
	tw.tween_property(greg, ^"global_position", popo.global_position - Vector2(24.0, 0.0), 1.0)
	tw.tween_callback(SND.play_song_from_beginning.bind("love"))
	tw.tween_callback(greg.animate.bind("walk_right"))
	tw.tween_callback(love_gradient.show)
	tw.tween_property(love_gradient, ^"modulate:a", 1.0, 2.0).from(0.0)
	var dlg := DialogueBuilder.new().set_char("popo_1").set_emo("blush")
	dlg.al("hey... you made it...")
	dlg.al("i can see that [color=%s]rose[/color] in your pocket..." % dlg.FLOWERCOLOR).semotion("blushlook")
	dlg.al("...")
	dlg.al("the sunset is beautiful, isn't it...?").semotion("blush")
	dlg.al("it happens every day...")
	dlg.al("but today, it feels so special...")
	dlg.al("because you're here with me...").semotion("blushlook")
	dlg.al("...").semotion("blush")
	dlg.al("ever since i was assigned to this town...")
	dlg.al("i've been so bored.")
	dlg.al("no-one willingly talks to the police...")
	dlg.al("...because we're supposed to keep watch over them.")
	dlg.al("make sure they don't get out of hand or leave...")
	dlg.al("there's no action... no romance here.")
	dlg.al("until... you came...").semotion("blushlook")
	dlg.al("so brave... so absentminded...")
	dlg.al("i guess you didn't even realise you came to the police.").semotion("blush")
	dlg.al("this... courage... it makes my heart pump like crazy...")
	dlg.al("and you kept coming back with new and new feats...").semotion("blushlook")
	dlg.al("i wish i knew your name, because... [color=f18]i love you...").semotion("blush")
	dlg.al("let's have our first date today.").semotion("blushlook")
	dlg.al("let's go to the east of town... hang out at the skatepark...")
	dlg.al("let's explore the abandoned factory...")
	dlg.al("let's ████ █████ with ███ ██████ in the chapel...").semotion("blush")
	dlg.al("then you give me the [color=%s]rose[/color]..." % dlg.FLOWERCOLOR).scallback(func() -> void:
		SND.current_song_player.pitch_scale = 0.95
		popo_sprite.play(&"walk_left", 0.0)
		popo_sprite_s.play(&"walk_left", 0.0)
	)
	dlg.al("and we can explore its power, together... forever.").semotion("blushlook")
	dlg.clear_emo()
	dlg.al("lemme lift this blockade, first.")
	dlg.al("hey! get out of our way! we're walkin' here!").scallback(func() -> void:
		popo_sprite.play(&"walk_right", 0.0)
		popo_sprite_s.play(&"walk_right", 0.0)
	)
	tw.tween_callback(dlg.speak_choice)
	tw.tween_await(SOL.dialogue_closed)
	tw.tween_callback(love_gradient.hide)
	tw.tween_callback(SND.play_song.bind("", 100.0))
	var rng := RandomNumberGenerator.new()
	for i in 12:
		tw.tween_callback(anim.advance.bind(99999.0))
		tw.tween_callback((anim.play if Math.true_or_false(rng) else anim.play_backwards).bind("slide"))
		tw.tween_interval(randf() * 0.2 + randfn(0.1, 0.05))
	tw.tween_callback(anim.stop)
	tw.tween_callback(SND.play_sound.bind(preload("res://sounds/car_overrun.ogg")))
	tw.tween_property(cars, ^"global_position:x", popo.global_position.x - 16, 0.5)
	tw.tween_callback(SOL.vfx.bind("explosion", popo.global_position, {parent = popo.get_parent()}))
	tw.tween_callback(popo._car_collision_response.bind(popo.global_position, popo.global_position + Vector2(-5, -2), 0.00015))
	tw.tween_callback(cars_audio.stop)
	tw.tween_callback(cars.hide)
	tw.tween_interval(3.0)
	tw.tween_callback(func() -> void:
		science_guy.default_lines = ["science_guy_free_1", "science_guy_free_2"]
		greg.animate("walk_down")
		greg.raycast.target_position = Vector2.DOWN
		DAT.free_player("cutscene")
		room.play_room_music(1.0)
		CarOverworld.static_paused = false
		DAT.set_data("popo_blockade_lifted", true)
		queue_free()
	)
