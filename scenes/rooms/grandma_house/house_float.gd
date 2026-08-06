extends Node

const M = preload("res://scenes/vfx/x_menacing.gd")
const SP = preload("res://scenes/gui/x_speech_buble.gd")

const GIGLE = preload("res://sounds/x/gigle.tres")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var menacing: M = $"../Menacing"
@onready var speech_buble: SP = $"../SpeechBuble"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var fade: ColorRect = $"../Fade"
@onready var second_music: AudioStreamPlayer = $"../SecondMusic"
@onready var ambient: AudioStreamPlayer = $"../Ambient"
@onready var overlay: AnimationPlayer = $Overlay


func _ready() -> void:
	fade.show()
	DAT.capture_player("cutscene")
	_c1.call_deferred()


func _c1() -> void:
	menacing.particles(0.75)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(fade, ^"modulate:a", 0.0, 6.0).set_ease(Tween.EASE_IN)
	tw.tween_interval(1.0)
	tw.tween_property(menacing, "global_position:y", greg.global_position.y - 20, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		var dlg := DialogueBuilder.new()
		dlg.al("btw")
		dlg.al("my boss IS actually coming to check up here")
		dlg.al("so i cant have your ass out there.")
		dlg.al("ill keep you safe in here instead :)")
		dlg.al("have fun walking around your room and thinking")
		dlg.al("and all the other fleshy stuff")
		dlg.al("since i didn't turn you into stone")
		dlg.al("it's going to be tricky to preserve you like this")
		dlg.al("so hope i don't forget to check up on you.")
		dlg.al("but...")
		dlg.al("we'll find another use for you.")
		dlg.al("for sure.")
		dlg.al("bye LOL")
		speech_buble.repos(speech_buble.wpos_to_local(menacing.global_position, camera))
		speech_buble.exhibit()
		await speech_buble.speak(dlg.get_dial())
		_c2.call_deferred()
	)


func _c2() -> void:
	SND.play_sound(GIGLE, {"bus": "ECHO", "volume": -4})
	second_music.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(menacing, "global_position:y", menacing.global_position.y - 120, 1.0)
	overlay.play(&"end")
