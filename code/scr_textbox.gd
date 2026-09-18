extends RichTextLabel
class_name TextBox

# this is a basic scrolling text box

signal speak_finished
signal letter_spoken(letter: String, ix: int)

const SHORT_WAIT := ".,:;?!"

var _bbcodeless_text: String

var _text_speak_time := 1.0
var _speak_time_mul := 1.0
var _speaking_speed := 1.0


func _ready() -> void:
	visible_ratio = 0.0 # we use builtin visible_ratio to do the blablbalb
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	bbcode_enabled = true


var _t := 0.0

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_t += delta
	var need := _speaking_speed * _text_speak_time * _speak_time_mul * 0.04
	if _t > need and visible_ratio < 1.0:
		_t = 0.0
		_next_letter()


func speak_text(options := {}):
	_speaking_speed = 1.0 / options.get("speed", 1.0) as float
	_speak_time_mul = 1.0
	_text_speak_time = OPT.get_opt("text_speak_time")
	_bbcodeless_text = get_parsed_text()
	skip_to_end()
	visible_ratio = 0.0
	_t = 0.0


func _next_letter() -> void:
	var letter := _bbcodeless_text[visible_characters] if not _bbcodeless_text.is_empty() else ""
	#print(letter, "\b")
	visible_characters += 1
	letter_spoken.emit(letter, visible_characters - 1)
	_speak_time_mul = 1.0
	if letter in SHORT_WAIT:
		_speak_time_mul = 6.0
		if visible_characters + 1 < _bbcodeless_text.length():
			if _bbcodeless_text[visible_characters + 1] in SHORT_WAIT:
				_speak_time_mul = 0.0

	if visible_ratio >= 1.0:
		speak_finished.emit()
		skip_to_end()


func skip_to_end():
	if visible_ratio < 1.0:
		speak_finished.emit()
	visible_ratio = 1.0
