class_name DialogueBuilder

var _dial: Dialogue

var _cur_char: StringName
var _cur_emo: StringName
var _cur_choice_link: String


func _init() -> void:
	_dial = Dialogue.new()


func set_char(ch: StringName) -> DialogueBuilder:
	_cur_char = ch
	return self


func clear_char() -> DialogueBuilder:
	_cur_char = &""
	return self


func clear_emo() -> DialogueBuilder:
	_cur_emo = &""
	return self


func clear_choice_link() -> DialogueBuilder:
	_cur_choice_link = &""
	return self


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


func get_dial() -> Dialogue:
	var d := _dial
	_dial = null
	return d


func speak() -> void:
	SOL.dialogue_d(get_dial())


func speak_choice() -> StringName:
	speak()
	await SOL.dialogue_closed
	var c := SOL.dialogue_choice
	return c
