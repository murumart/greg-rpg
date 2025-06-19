class_name Sunsetter extends Node

const SUNSET_LEVEL := 72
const SUNSET_COLOR := Color(1.0, 0.651, 0.576)
const TRIGGER_KEY := &"sunset_triggered"

@export var sky_modulate: ColorContainer
@export var room: Room
@export var sunset_music := ""
@export var sunset_trigger_gates: Array[StringName]


func _ready() -> void:
	var lvl := ResMan.get_character("greg").level
	var t := _sunset_triggered()
	if t or lvl >= SUNSET_LEVEL and _correct_gate():
		sky_modulate.color = SUNSET_COLOR
		if sunset_music:
			room.music = sunset_music
		if not t:
			DAT.set_data(TRIGGER_KEY, true)


func _correct_gate() -> bool:
	return sunset_trigger_gates.is_empty() or LTS.gate_id in sunset_trigger_gates


func _sunset_triggered() -> bool:
	return DAT.get_data(TRIGGER_KEY, false)
