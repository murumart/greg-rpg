extends Node2D

const CT := preload("res://scenes/tech/scr_camera.gd")
const SP := preload("res://scenes/gui/x_speech_buble.gd")
const M := preload("res://scenes/vfx/x_menacing.gd")
const RG := preload("res://scenes/tech/scr_room_gate.gd")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var flower_darkness: Sprite2D = $"../FlowerDarkness"
@onready var camera: CT
@onready var speech_buble: SP = $SpeechBuble
@onready var mdp: M = $Menacing

@onready var note: Sprite2D = $"../Decor/Note"
@onready var carpet: Sprite2D = $"../Decor/Carpet"
@onready var carnations: Sprite2D = $"../Decor/Carnations"
@onready var door: Sprite2D = $"../Door"
@onready var room_gate: RG = $"../Areas/RoomGate"


func _ready() -> void:
	if LTS.gate_id != &"afterexpo":
		queue_free()
		return
	camera = $"../Greg/Camera"
	DAT.capture_player("cutscene")
	greg.global_position = global_position
	flower_darkness.hide.call_deferred()
	camera.resolution_scale_factor = 0.25
	camera.zoom = Math.v2(4)
	camera.update_window_stuff()
	speech_buble.spam_sound = null
	_c1.call_deferred()
	mdp.show()
	if is_instance_valid(note): note.queue_free()
	if is_instance_valid(carpet): carpet.queue_free()
	if is_instance_valid(carnations): carnations.queue_free()
	if is_instance_valid(door): door.queue_free()
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 1.0, {kill_rects = true})
	room_gate.destination = &"house_float"


func _c1() -> void:
	var dlg := DialogueBuilder.new()
	var tw := create_tween()
	mdp.go_light()
	mdp.particles(0.01)
	mdp.flip()
	mdp.face_o()
	tw.tween_interval(0.5)
	tw.tween_callback(greg.animate.bind("walk_right"))
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		speech_buble.spam_sound = mdp.speech_snd
		var speechparent := speech_buble.get_parent()
		speechparent.global_position.y += 30
		SND.play_song_from_beginning("bells", 80, {"pitch_scale": 0.2})
		dlg.al("your house... i'll miss it.").scallback(mdp.flip)
		dlg.al("it gave me some more purpose... or the feeling of one.")
		dlg.al("but i think... this town. it's very isolated.").scallback(mdp.flip)
		dlg.al("i started ignoring the world here").scallback(mdp.face_tilt)
		dlg.al("and getting lost in the SECRET GARDEN i found...").scallback(mdp.face_dark)
		dlg.al("until i realised i'm in a big hurry, actually!").scallback(func() -> void:
			mdp.flip()
			mdp.face_smile()
		)
		dlg.al("so let's get this over with.").scallback(mdp.face_4)
		dlg.al("...i don't have any big words left for you.").scallback(mdp.face_default)
		dlg.al("you have your house back.").scallback(func() -> void:
			mdp.flip()
			mdp.face_handout()
		)
		dlg.al("enjoy boy. bye").scallback(func()->void:
			mdp.sound_giggle()
			mdp.face_4()
			mdp.flip()
			mdp.bounce(1.0)
		)
		_repos()
		speech_buble.exhibit()
		await speech_buble.speak(dlg.get_dial())
		SND.play_song("", 0.3)
		_c2.call_deferred()
	)


func _c2() -> void:
	mdp.go_dark()
	mdp.splode()
	mdp.particles(0.6)
	mdp.explode_sound.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.7)
	tw.tween_callback(mdp.swoop_sound.play)
	tw.tween_property(mdp, "position", mdp.position + Vector2(0, -500), 2.0)
	tw.tween_callback(mdp.hide)
	tw.tween_callback(DAT.free_player.bind("cutscene"))


func _repos() -> void:
	speech_buble.repos(speech_buble.wpos_to_local(mdp.global_position + Vector2(-18, -6), camera))
