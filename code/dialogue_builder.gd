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


func set_emo(emo: StringName) -> DialogueBuilder:
	_cur_emo = emo
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


func reset() -> DialogueBuilder:
	_dial = Dialogue.new()
	return self


func get_dial() -> Dialogue:
	return _dial


func speak(box: DialogueBox = null) -> void:
	if not box:
		SOL.dialogue_d(get_dial())
		return
	box.prepare_dialogue_d(_dial)


func speak_choice(box: DialogueBox = null) -> StringName:
	speak(box)
	if not box:
		await SOL.dialogue_closed
	else:
		await box.dialogue_closed
	var c: StringName = SOL.dialogue_choice
	SOL.dialogue_choice = &""
	return c


static func ml(text: String) -> DialogueLine:
	return DialogueLine.mk(text)
