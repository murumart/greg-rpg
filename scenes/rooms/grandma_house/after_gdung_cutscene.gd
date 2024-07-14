extends Node2D

@onready var enter_area: Area2D = $EnterArea
@onready var camera: Camera2D = $"../../Greg/Camera"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var grandma: OverworldCharacter = $Grandma
@onready var color_container: ColorContainer = $"../../CanvasModulateGroup/ColorContainer"


func _ready() -> void:
	enter_area.body_entered.connect(_close_cutscene.unbind(1))


func _close_cutscene() -> void:
	DAT.capture_player("cutscene")
	greg.animate("walk_up")
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.0)
	tw.tween_property(camera, "global_position",
			((greg.global_position + grandma.global_position) * 0.5).ceil(), 3.0)
	tw.tween_callback(func():
		SOL.vfx("sleepy", grandma.global_position, {"parent": grandma})
		SOL.vfx("sleepy", grandma.global_position, {"parent": grandma})
		SOL.vfx("sleepy", grandma.global_position, {"parent": grandma})
		SOL.dialogue("grandma_final_meeting_1")
		await SOL.dialogue_closed
		SND.play_sound(preload("res://sounds/enter_battle_grandma.ogg"))
		LTS.enter_battle(preload("res://resources/battle_infos/grandma_bossfight.tres"))
	)
