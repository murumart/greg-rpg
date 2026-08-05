extends Node

const M = preload("res://scenes/vfx/x_menacing.gd")
const SP = preload("res://scenes/gui/x_speech_buble.gd")

const GIGLE = preload("res://sounds/x/gigle.tres")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var menacing: M = $"../Menacing"
@onready var speech_buble: SP = $"../SpeechBuble"
@onready var camera: Camera2D = $"../Greg/Camera"


func _ready() -> void:
	DAT.capture_player("cutscene")
	_c1.call_deferred()


func _c1() -> void:
	menacing.particles(0.75)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.0)
	tw.tween_property(menacing, "global_position:y", greg.global_position.y - 20, 1.0)
	tw.tween_callback(func() -> void:
		var dlg := DialogueBuilder.new()
		dlg.al("btw")
		dlg.al("my boss IS actually coming to check up here")
		dlg.al("so i cant have your ass out there.")
		dlg.al("i really wanted to keep you around anyway :)")
		dlg.al("so enjoy.")
		dlg.al("bye 2")
		speech_buble.repos(speech_buble.wpos_to_local(menacing.global_position, camera))
		speech_buble.exhibit()
		await speech_buble.speak(dlg.get_dial())
		_c2.call_deferred()
	)


func _c2() -> void:
	SND.play_sound(GIGLE, {"bus": "ECHO"})
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(menacing, "global_position:y", menacing.global_position.y - 120, 1.0)
