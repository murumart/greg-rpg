extends Node2D

const CT := preload("res://scenes/tech/scr_camera.gd")
const SP := preload("res://scenes/gui/x_speech_buble.gd")
const M := preload("res://scenes/vfx/x_menacing.gd")
const RG := preload("res://scenes/tech/scr_room_gate.gd")

const S_EEP = preload("res://sounds/x/eep.ogg")
const S_HEH = preload("res://sounds/x/heh.ogg")
const S_HMPH = preload("res://sounds/x/hmph.ogg")
const S_EHEH = preload("res://sounds/x/eheh.ogg")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var flower_darkness: Sprite2D = $"../FlowerDarkness"
@onready var camera: CT
@onready var speech_buble: SP = $SpeechBuble
@onready var mdp: Node2D = $mdp
@onready var mdpsprite: AnimatedSprite2D = $mdp/mdp
@onready var menacing: M = $Menacing
@onready var shake_sound: AudioStreamPlayer = $mdp/ShakeSound
@onready var giggle: AudioStreamPlayer = $mdp/Giggle1
@onready var speech: AudioStreamPlayer = $mdp/Speech

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
	menacing.show()
	speech_buble.spam_sound = null
	mdp.hide()
	_c1.call_deferred()
	_face_default()
	if is_instance_valid(note): note.queue_free()
	if is_instance_valid(carpet): carpet.queue_free()
	if is_instance_valid(carnations): carnations.queue_free()
	if is_instance_valid(door): door.queue_free()
	room_gate.destination = &"house_float"


var tweener: Tween

func _c1() -> void:
	var dlg := DialogueBuilder.new()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(greg.animate.bind("walk_right"))
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		var speechparent := speech_buble.get_parent()
		speechparent.global_position.y += 15
		SND.play_song_from_beginning("bells", 80, {"pitch_scale": 0.7})
		dlg.al("congratulations").stext_speed(4)
		dlg.al("...to me!").scallback(func() -> void:
			speech_buble.spam_sound = speech
			_stopanim()
			_face_smile()
			mdp.show()
			menacing.hide()
			SND.play_sound(S_HEH)
			SOL.vfx("dustpuff", mdp.global_position, {parent = mdp})
			SND.play_song("", 80)
		)
		dlg.al("i really didn't know how i was gonna fix all of that").scallback(func() -> void:
			_bounce(1.0)
			_face_default()
			SND.play_song_from_beginning("beyond", 0.1, {"pitch_scale": 1.0})
		)
		dlg.al("y'know... it's hard to remember who got them.").scallback(func() -> void:
			_face_o()
			SND.play_sound(S_HMPH)
			speech_buble.spam_sound = null
		)
		dlg.al("the FLOWERS").scallback(func() -> void:
			_flip()
			_stopanim()
			giggle.play()
			speech_buble.spam_sound = speech
		)
		dlg.al("and like").scallback(func() -> void:
			_face_default()
		)
		dlg.al("even if i went to grab them back").scallback(func() -> void:
			_face_worm()
		)
		dlg.al("no way there wouldnt be a fight.")
		dlg.al("that Isn't Good...").scallback(func() -> void:
			_flip()
			_face_dark()
		)
		dlg.al("but a fellow ant going rogue... no-one would bat an eye").scallback(func() -> void:
			_face_tilt()
			_bounce(1.2)
		)
		dlg.al("cept me i guess").scallback(func() -> void:
			_face_smile()
			_stopanim()
		)
		dlg.al("you werent supposed to enter my SECRET GARDEN").scallback(func() -> void:
			_face_big()
		)
		dlg.al("didn't you read the note..?").scallback(func() -> void:
			_shake()
			shake_sound.play()
			SND.play_sound(S_HMPH)
		)
		dlg.al("whatevs. gig's up anyway").scallback(func() -> void:
			_face_default()
			_flip()
			_bounce(1.0)
			shake_sound.stop()
		)
		dlg.al("my boss won't be seeing any of this \"florist\" crap")
		dlg.al("so... you win!").scallback(func() -> void:
			_flip()
			_face_4()
			SND.play_sound(S_EEP)
		)
		dlg.al("you have your little house back").scallback(func() -> void:
			_stopanim()
			speech_buble.spam_sound = null
		)
		dlg.al("enjoy boy. ..... bye").scallback(func() -> void:
			_face_default()
			giggle.play()
		)
		_repos()
		speech_buble.exhibit()
		await speech_buble.speak(dlg.get_dial())
		SND.play_song("", 0.3)
		_c2.call_deferred()
	)


func _c2() -> void:
	mdp.hide()
	menacing.show()
	menacing.splode()
	menacing.particles(0.6)
	menacing.explode_sound.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.7)
	tw.tween_callback(menacing.swoop_sound.play)
	tw.tween_property(menacing, "position", menacing.position + Vector2(0, -500), 2.0)
	tw.tween_callback(menacing.hide)
	tw.tween_callback(DAT.free_player.bind("cutscene"))


func _repos() -> void:
	speech_buble.repos(speech_buble.wpos_to_local(mdp.global_position + Vector2(-18, -6), camera))


func _stopanim() -> void:
	if is_instance_valid(tweener) and tweener.is_valid(): tweener.kill()
	mdp.scale = Vector2.ONE
	mdpsprite.position = Vector2.ZERO


func _bounce(speed: float) -> void:
	_stopanim()
	tweener = create_tween().set_trans(Tween.TRANS_CUBIC).set_loops()
	tweener.tween_property(mdp, ^"scale", Vector2(1.1, 0.9), 0.8 / speed)
	tweener.tween_property(mdp, ^"scale", Vector2(0.9, 1.1), 0.8 / speed)


func _shake() -> void:
	_stopanim()
	tweener = create_tween().set_loops()
	tweener.tween_callback(func() -> void: mdpsprite.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)))
	tweener.tween_interval(0.01)


func _stretch() -> void:
	mdp.scale = Vector2(1.1, 0.9)


func _face_4() -> void: mdpsprite.animation = "4"
func _face_big() -> void: mdpsprite.animation = "big"
func _face_dark() -> void: mdpsprite.animation = "dark"
func _face_default() -> void: mdpsprite.animation = "default"
func _face_o() -> void: mdpsprite.animation = "o"
func _face_smile() -> void: mdpsprite.animation = "smile"
func _face_tilt() -> void: mdpsprite.animation = "tilt"
func _face_worm() -> void: mdpsprite.animation = "worm"
func _flip() -> void: mdpsprite.flip_h = not mdpsprite.flip_h
