extends Node2D

@onready var camera_area: Area2D = $CameraArea
@onready var ladder: Sprite2D = $Ladder
@onready var ladder_place: InteractionArea = $LadderPlace
@onready var climbing_place := $ClimbingPlace

@export var cam: Camera2D
@export var greg: PlayerOverworld

var time := 0.75
var ladder_active: bool:
	set(to): DAT.set_data("mayor_ladder_actieve", to)
	get: return DAT.get_data("mayor_ladder_actieve", false)
var climping := false


func _ready() -> void:
	camera_area.body_entered.connect(_cam_in.unbind(1))
	camera_area.body_exited.connect(_cam_out.unbind(1))
	ladder_place.interacted.connect(_ladder_interacted)
	_ladder_display()


func _ladder_display() -> void:
	ladder.visible = ladder_active
	if not ladder_active:
		ladder.global_position = Vector2(999999, 99999)
	else:
		ladder.position = Vector2(-43, 78)


func _ladder_interacted() -> void:
	var g := ResMan.get_character("greg")
	if not ladder_active and &"ladder" in g.inventory:
		ladder_active = true
		g.inventory.erase(&"ladder")
		_ladder_display()
		SND.play_sound(preload("res://sounds/use_item.ogg"))
		SOL.dialogue("ladder_added")
	elif ladder_active:
		print("you ladder.")
		climbing_place.begin_climping()


func _cam_in() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"global_position:y", global_position.y + 28, time)


func _cam_out() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"position:y", -9, time)
