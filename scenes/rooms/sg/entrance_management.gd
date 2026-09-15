extends Sprite2D

const RoomGate = preload("res://scenes/tech/scr_room_gate.gd")

@export var gold_inspect: InspectArea
@export var blue_inspect: InspectArea
@export var pink_inspect: InspectArea
@export var green_inspect: InspectArea
@onready var inspects := [gold_inspect, blue_inspect, pink_inspect, green_inspect]

@export var gold_entrance: RoomGate
@export var blue_entrance: RoomGate
@export var pink_entrance: RoomGate
@export var green_entrance: RoomGate
@onready var entrances: Array[RoomGate] = [
	gold_entrance,
	blue_entrance,
	pink_entrance,
	green_entrance,
]

@onready var enter_side: Area2D = $"../Areas/EnterSide"
@onready var exit_side: Area2D = $"../Areas/ExitSide"


func _ready() -> void:
	if DAT.get_data("sg_y_7_boss_done", false):
		$"..".music = "secret_garden"
		%Darkness.hide()
	else:
		$"..".music = "bells"

	if DAT.get_data("sg_b4_multipanther_fought", false):
		%Black.hide()
		%Stars.show()

	for en in entrances:
		en.visible = en.predicate.check() == Predicate.SUCCESS


	enter_side.body_entered.connect(func(_b) -> void:
		SND.play_song("", 3.0)
	)

	exit_side.body_entered.connect(func(_b) -> void:
		$"..".play_room_music(3.0)
	)

	#if DAT.get_data("sg_y_7_boss_done", false):
	#	%BEntrance.disabled = false
	#	%BEntrance.show()
	#if DAT.get_data("sg_b4_multipanther_fought", false):
	#	%PEntrance.disabled = false
	#	%PEntrance.show()
	#if DAT.get_data("x_chase_done", false):
	#	%FinalEntrance.disabled = false
	#	%FinalEntrance.show()
