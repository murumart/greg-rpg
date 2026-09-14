extends Node

const M = preload("res://scenes/vfx/x_menacing.gd")
const SP = preload("res://scenes/gui/x_speech_buble.gd")
const Credits = preload("res://scenes/gui/scr_end_credits.gd")

const GIGLE = preload("res://sounds/x/gigle.tres")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var menacing: M = $"../Menacing"
@onready var speech_buble: SP = $"../SpeechBuble"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var fade: ColorRect = $"../Fade"
@onready var second_music: AudioStreamPlayer = $"../SecondMusic"
@onready var ambient: AudioStreamPlayer = $"../Ambient"
@onready var overlay: AnimationPlayer = $Overlay
@onready var end_credits: Credits = $EndCredits


func _ready() -> void:
	remove_child(end_credits)
	fade.show()
	DAT.capture_player("cutscene")
	_c1.call_deferred()


func _c1() -> void:
	menacing.particles(0.75)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	greg.animate("walk_down", true, 0.25)
	tw.tween_property(fade, ^"modulate:a", 0.0, 6.0).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(greg, "position:y", greg.position.y, 5.0).from(greg.position.y - 12)
	tw.parallel().tween_callback(greg.animate.bind("walk_down")).set_delay(5.0)
	tw.tween_interval(1.0)
	speech_buble.spam_sound = menacing.speech_snd
	tw.tween_callback(greg.animate.bind("walk_left")).set_delay(1.25)
	tw.tween_property(menacing, "global_position:y", greg.global_position.y - 20, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		var dlg := DialogueBuilder.new()
		dlg.al("by the way")
		dlg.al("i still can't let you go out on the streets.")
		dlg.al("so enjoy your homely environment.")
		dlg.al("with your flesh and your thoughts intact...")
		dlg.al("no stone to stop decay.")
		dlg.al("just hope i don't forget to check up on you")
		dlg.al("to freshen you up every now and then")
		dlg.al("because you might just rot away into nothing")
		dlg.al("which wouldn't be great")
		dlg.al("because of your potential to change the world")
		dlg.al("...in some more controlled context.")
		dlg.al("we'll meet again... if i come up with something.")
		dlg.al("i'll try.")
		dlg.al("okay bye")
		speech_buble.spam_sound = menacing.speech_snd
		speech_buble.repos(speech_buble.wpos_to_local(menacing.global_position, camera))
		speech_buble.exhibit()
		await speech_buble.speak(dlg.get_dial())
		_c2.call_deferred()
	)


func _c2() -> void:
	menacing.giggle_snd.volume_db = -4.0
	menacing.sound_giggle()
	second_music.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(menacing, "global_position:y", menacing.global_position.y - 120, 1.0)
	tw.tween_callback(greg.animate.bind("walk_down")).set_delay(3.0)
	overlay.play(&"end")
	tw.tween_callback(func() -> void:
		var e: Array = DIR.gej(3, [])
		e.append(4)
		DIR.sej(3, e)
		SOL.add_ui_child(end_credits)
		await get_tree().process_frame
		end_credits.play()
	).set_delay(18)
