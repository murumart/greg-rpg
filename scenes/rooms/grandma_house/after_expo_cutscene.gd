extends Node2D

const CT := preload("res://scenes/tech/scr_camera.gd")
const SP := preload("res://scenes/gui/x_speech_buble.gd")

@onready var greg: PlayerOverworld = $"../Greg"
@onready var flower_darkness: Sprite2D = $"../FlowerDarkness"
@onready var camera: CT = $"../Greg/Camera"
@onready var speech_buble: SP = $SpeechBuble
@onready var mdp: Node2D = $mdp
@onready var mdpsprite: AnimatedSprite2D = $mdp/mdp
@onready var menacing: Node2D = $Menacing


func _ready() -> void:
	if LTS.gate_id != &"afterexpo":
		queue_free()
		return
	greg.global_position = global_position
	flower_darkness.hide.call_deferred()
	camera.resolution_scale_factor = 0.25
	camera.zoom = Math.v2(4)
	camera.update_window_stuff()
	_c1.call_deferred()

var tweener: Tween

func _c1() -> void:
	var dlg := DialogueBuilder.new()
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		var speechparent := speech_buble.get_parent()
		speechparent.global_position.y += 15
		_bounce(1.0)
		dlg.al("congratulations")
		dlg.al("...to me!").scallback(func() -> void:
			_stopanim()
			_face_smile()
		)
		dlg.al("").scallback(func() -> void:
			_bounce(1.0)
			_face_default()
		)
		_repos()
		speech_buble.exhibit()
		speech_buble.speak(dlg.get_dial())
	)


func _repos() -> void:
	speech_buble.repos(speech_buble.wpos_to_local(mdp.global_position + Vector2(-18, -6), camera))


func _stopanim() -> void:
	if is_instance_valid(tweener) and tweener.is_valid(): tweener.kill()


func _bounce(speed: float) -> void:
	_stopanim()
	tweener = create_tween().set_trans(Tween.TRANS_CUBIC).set_loops()
	tweener.tween_property(mdp, ^"scale", Vector2(1.1, 0.9), 0.8 / speed)
	tweener.tween_property(mdp, ^"scale", Vector2(0.9, 1.1), 0.8 / speed)


func _face_4() -> void: mdpsprite.animation = "4"
func _face_big() -> void: mdpsprite.animation = "big"
func _face_dark() -> void: mdpsprite.animation = "dark"
func _face_default() -> void: mdpsprite.animation = "default"
func _face_o() -> void: mdpsprite.animation = "o"
func _face_smile() -> void: mdpsprite.animation = "smile"
func _face_tilt() -> void: mdpsprite.animation = "tilt"
func _face_worm() -> void: mdpsprite.animation = "worm"
