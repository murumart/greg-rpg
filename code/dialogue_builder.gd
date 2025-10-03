class_name DialogueBuilder

const FLOWERCOLOR = "#99ff61"
const SPIRITCOLOR = "#7799ff"
const VAMPCOLOR = "#ff2089"
const PRESCOLOR = "#ff9999"
const SGD = "[font=res://fonts/gregorious_smaller.tres][font_size=16]"

var _dial: Dialogue

var _cur_char: StringName
var _cur_emo: StringName
var _cur_choice_link: String


func _init() -> void:
	_dial = Dialogue.new()


func set_char(ch: StringName) -> DialogueBuilder:
	assert(ch in ResMan.characters)
	_cur_char = ch
	return self


func clear_char() -> DialogueBuilder:
	_cur_char = &""
	return self


func set_emo(emo: StringName) -> DialogueBuilder:
	_cur_emo = emo
	return self


func clear_emo() -> DialogueBuilder:
	_cur_emo = &""
	return self


func clear_choice_link() -> DialogueBuilder:
	_cur_choice_link = &""
	return self


func al(txt: String) -> DialogueLine:
	var line := ml(txt)
	add_line(line)
	return line


func add_line(line: DialogueLine) -> DialogueBuilder:
	_dial.add_line(line)

	if not line.character:
		line.character = _cur_char
	elif line.character != _cur_char:
		_cur_char = line.character

	if not line.emotion:
		line.emotion = _cur_emo
	elif line.emotion != _cur_emo:
		_cur_emo = line.emotion

	if not line.choice_link:
		line.choice_link = _cur_choice_link
	elif line.choice_link != _cur_choice_link:
		_cur_choice_link = line.choice_link
	return self


func reset() -> DialogueBuilder:
	_dial = Dialogue.new()
	return self


func clear() -> DialogueBuilder:
	clear_emo()
	clear_char()
	reset()
	return self


func get_dial() -> Dialogue:
	return _dial


func speak(box: DialogueBox = null) -> void:
	assert(_dial.size() > 0, "dialogue needs lines to be spoken.... dumpass")
	var toosmall := _dial.size() <= 0
	if toosmall: # hopefully harmless safeguard
		al("...")
	if not box:
		SOL.dialogue_d(_dial)
		if toosmall: _dial.lines.resize(_dial.lines.size() - 1)
		return
	box.prepare_dialogue_d(_dial)
	if toosmall: _dial.lines.resize(_dial.lines.size() - 1)


func speak_choice(box: DialogueBox = null) -> StringName:
	speak(box)
	if not box:
		await SOL.dialogue_closed
	else:
		await box.dialogue_closed
	var c: StringName = SOL.dialogue_choice
	SOL.dialogue_choice = &""
	return c


func is_empty() -> bool:
	return _dial.size() <= 0


static func ml(text: String) -> DialogueLine:
	return DialogueLine.mk(text)
