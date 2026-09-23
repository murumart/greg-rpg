extends Node2D

@onready var detect := $DetectionArea as Area2D
@onready var anim := $AnimationPlayer as AnimationPlayer

@onready var love_gradient: Sprite2D = $Love

@onready var popo: OverworldCharacter = $PopoRomantic
@onready var popo_sprite: AnimatedSprite2D = $PopoRomantic/Sprite
@export var greg: PlayerOverworld
@export var science_guy: OverworldCharacter


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
	DAT.capture_player("cutscene")
	SND.play_song("")
	var tw := create_tween()
	tw.tween_property(greg, ^"global_position", popo.global_position - Vector2(24.0, 0.0), 1.0)
	tw.tween_callback(SND.play_song_from_beginning.bind("love"))
	tw.tween_callback(greg.animate.bind("walk_right"))
	tw.tween_callback(love_gradient.show)
	tw.tween_property(love_gradient, ^"modulate:a", 1.0, 2.0).from(0.0)
