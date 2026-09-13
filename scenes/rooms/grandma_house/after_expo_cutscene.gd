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
	room_gate.destination = &"house_float"


func _c1() -> void:
	var dlg := DialogueBuilder.new()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(greg.animate.bind("walk_right"))
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		var speechparent := speech_buble.get_parent()
		speechparent.global_position.y += 30
		SND.play_song_from_beginning("bells", 80, {"pitch_scale": 0.7})
		dlg.al("to save the WORLD").stext_speed(4)
		dlg.al("just have some dolt nab the FLOWERS").scallback(func() -> void:
			mdp.sound_giggle()
			mdp.stopanim()
			mdp.face_smile()
			mdp.go_light()
			mdp.sound_heh()
			SOL.vfx("dustpuff", mdp.global_position, {parent = mdp})
			SND.play_song("", 80)
		)
		dlg.al("i owe you one, buddy").scallback(func() -> void:
			speech_buble.spam_sound = mdp.speech_snd
			mdp.bounce(1.0)
			mdp.face_default()
			SND.play_song_from_beginning("beyond", 0.1, {"pitch_scale": 1.0})
		)
		dlg.al("y'know... it's hard to remember who got them.").scallback(func() -> void:
			mdp.face_o()
			mdp.sound_hmph()
		)
		dlg.al("the FLOWERS").scallback(func() -> void:
			mdp.flip()
			mdp.stopanim()

			speech_buble.spam_sound = mdp.speech_snd
		)
		dlg.al("and like").scallback(func() -> void:
			mdp.face_default()
		)
		dlg.al("even if i went to grab them back myself").scallback(func() -> void:
			mdp.face_worm()
		)
		dlg.al("no way there wouldnt be a fight.")
		dlg.al("that Isn't Good... ").scallback(func() -> void:
			mdp.flip()
			mdp.face_dark()
		)
		dlg.al("not supposed to duke it out with residents.")
		dlg.al("but a fellow ant going rogue... no-one would bat an eye").scallback(func() -> void:
			mdp.face_tilt()
			mdp.bounce(1.2)
		)
		dlg.al("until he goes REALLY rogue i guess").scallback(func() -> void:
			mdp.face_smile()
			mdp.stopanim()
		)
		dlg.al("you werent supposed to enter my SECRET GARDEN").scallback(func() -> void:
			mdp.face_big()
		)
		dlg.al("didnt you read the note..?").scallback(func() -> void:
			mdp.move_mode = mdp.MoveMode.FOLLOW
			mdp.shake()
			mdp.shake_sound.play()
			mdp.sound_hmph()
		)
		dlg.al("i was PREPARING to gracefully collect you.")
		dlg.al("whatevs. we met in the end...").scallback(func() -> void:
			mdp.face_default()
			mdp.flip()
			mdp.bounce(1.0)
			mdp.shake_sound.stop()
			mdp.move_mode = mdp.MoveMode.STOP
			mdp.position = Vector2(24, -10)
		)
		dlg.al("we got our differences sorted out")
		dlg.al("one of your floral friends even got to show me his REFLECTION trick").scallback(func() -> void:
			mdp.face_big()
			mdp.stopanim()
			mdp.flip()
		)
		dlg.al("but whatevs!! the gig's up anyway").scallback(func() -> void:
			mdp.face_default()
			mdp.flip()
			mdp.bounce(1.0)
			mdp.shake_sound.stop()
		)
		dlg.al("my boss wont be seeing any of this \"florist\" crap")
		dlg.al("so... you win!").scallback(func() -> void:
			mdp.flip()
			mdp.face_4()
			mdp.sound_eep()
		)
		dlg.al("you have your little house back").scallback(func() -> void:
			mdp.stopanim()
			speech_buble.spam_sound = null
		)
		dlg.al("enjoy boy. ..... bye").scallback(func() -> void:
			mdp.face_default()
			mdp.sound_giggle()
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
