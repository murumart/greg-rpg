extends Resource
class_name DialogueLine

const MAX_TEXT_LENGTH := 66

@export_multiline var text := ""
@export var character : String = ""
@export var text_speed := 1.0

@export var choice_link := &""
@export var choices : PackedStringArray = []

@export var instaskip := false
