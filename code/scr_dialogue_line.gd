class_name DialogueLine extends Resource

# this stores dialogue text and such

const MAX_TEXT_LENGTH := 66

@export_multiline var text := ""
@export var character: String = ""
@export var emotion := ""
@export var text_speed := 1.0

@export var data_link := []
@export var choice_link := &""
@export var choices: PackedStringArray = []

@export var instaskip := false
@export var loop := -1

@export var item_to_give := &""
@export var spirit_to_give := &""
@export var silver_to_give := 0

@export var sound: AudioStream
@export var portrait_scale := Vector2.ONE

@export var set_data := []

@export var callback: Callable


static func mk(text_: String) -> DialogueLine:
	var l := DialogueLine.new()
	l.text = text_
	return l


func scharacter(to: String = "") -> DialogueLine:
	character = to
	return self


func semotion(to: String = "") -> DialogueLine:
	emotion = to
	return self


func stext_speed(to: float) -> DialogueLine:
	text_speed = to
	return self


func sdata_link(to: Array) -> DialogueLine:
	data_link = to
	return self


func sset_data(to: Array) -> DialogueLine:
	set_data = to
	return self


func schoice_link(to: String) -> DialogueLine:
	choice_link = to
	return self


func schoices(to: PackedStringArray) -> DialogueLine:
	choices = to
	return self


func sinstaskip(to: bool = true) -> DialogueLine:
	instaskip = to
	return self


func sloop(to: int) -> DialogueLine:
	loop = to
	return self


func scallback(to: Callable) -> DialogueLine:
	callback = to
	return self


func sitem_to_give(to: StringName) -> DialogueLine:
	item_to_give = to
	return self


func sspirit_to_give(to: StringName) -> DialogueLine:
	spirit_to_give = to
	return self


func ssilver_to_give(to: int) -> DialogueLine:
	silver_to_give = to
	return self


func ssound(to: AudioStream) -> DialogueLine:
	sound = to
	return self


func sportrait_scale(to: Vector2) -> DialogueLine:
	portrait_scale = to
	return self


func _to_string() -> String:
	var string := text
	if character:
		string = character + ": " + string
	if choices:
		string += "(%s)" % choices
	if choice_link:
		string = ("(%s)" % choice_link) + string
	return string
