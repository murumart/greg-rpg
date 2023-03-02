extends Resource
class_name DialogueLine

const MAX_TEXT_LENGTH := 66

@export_multiline var text := ""
@export var character : String = ""
@export var emotion := ""
@export var text_speed := 1.0

@export var choice_link := &""
@export var choices : PackedStringArray = []

@export var instaskip := false
@export var loop := -1

@export var item_to_give := &""
@export var spirit_to_give := &""
@export var silver_to_give := 0

@export var sound : AudioStream
