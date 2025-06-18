class_name Sunsetter extends Node

const SUNSET_LEVEL := 72
const SUNSET_COLOR := Color(1.0, 0.651, 0.576)

@export var sky_modulate: ColorContainer
@export var room: Room
@export var sunset_music := ""
@export var sunset_trigger_gates: Array[StringName]


func _ready() -> void:
	var lvl := ResMan.get_character("greg").level
	if lvl >= SUNSET_LEVEL and _correct_gate():
		sky_modulate.color = SUNSET_COLOR
		if sunset_music:
			room.music = sunset_music


func _correct_gate() -> bool:
	return sunset_trigger_gates.is_empty() or LTS.gate_id in sunset_trigger_gates
