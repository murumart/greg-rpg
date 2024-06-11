class_name Cellphone extends Node2D

const LEVELS_TEST_COUNT := 2
const TESTING_FOR_AREA := 0
const TESTTING_NOT_FOR_AREA := 1

const SND_CALL := preload("res://sounds/phone/phone_call.ogg")
const SND_END := preload("res://sounds/phone/call_end.ogg")
const READD_DESC := "uh... pretty sure you deleted this?"
const ITEM := preload("res://resources/items/res_cellphone.tres") as Item
const CSTART := "phone_"
const LVLUNDER := "_under"

var level := 1:
	get:
		return ResMan.get_character("greg").level
var room := "":
	get:
		return DAT.get_data("current_room", null) as String

@onready var scene := LTS.get_current_scene() as Node

@onready var special_area_detector: Area2D = $SpecialAreaDetector


func phonecall() -> void:
	print("calling!")
	var found_call := false
	SOL.dialogue("phone_dial")
	var init_id := CSTART + room
	var area := get_phone_area()
	SND.play_sound(SND_CALL)
	# format: phone_<room>_<area_name>_under<lvl>
	for test in LEVELS_TEST_COUNT:
		var test_id := init_id
		if test == TESTING_FOR_AREA:
			if not area:
				continue
			test_id += "_" + area
		for lvl in range(level + 1 + int(level % 2 == 0), 100, 2):
			var under_id := test_id + LVLUNDER + str(lvl)
			if SOL.dialogue_exists(under_id):
				SOL.dialogue(under_id)
				found_call = true
				break
		if SOL.dialogue_exists(test_id) and not found_call:
			SOL.dialogue(test_id)
			found_call = true
			break
	if found_call:
		SOL.dialogue("phone_call_over")
		return
	SOL.dialogue("phone_call_not_found")


# format: PhoneAreaAreaName -> area_name
func get_phone_area() -> String:
	var areas := special_area_detector.get_overlapping_areas()
	if areas:
		return areas[0].name.trim_prefix("PhoneArea").to_snake_case()
	return ""

