extends Resource
class_name DialogueLine

# this stores dialogue text and such

const MAX_TEXT_LENGTH := 66

@export_multiline var text := ""
@export var character: String = ""
@export var emotion := ""
@export var text_speed := 1.0

@export var data_link: PackedStringArray = []
@export var choice_link := &""
@export var choices: PackedStringArray = []

@export var instaskip := false
@export var loop := -1

@export var item_to_give := &""
@export var spirit_to_give := &""
@export var silver_to_give := 0

@export var sound: AudioStream
@export var portrait_scale := Vector2.ONE

@export var set_data: PackedStringArray = []


func _to_string() -> String:
	var string := text
	if character:
		string = character + ": " + string
	if choices:
		string += "(%s)" % choices
	if choice_link:
		string = ("(%s)" % choice_link) + string
	return string
