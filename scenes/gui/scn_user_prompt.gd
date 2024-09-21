class_name UserPrompt extends Control

signal submitted(data: Variant)
signal text_changed(text: String)

enum {
	SHOW_TITLE,
	TITLE,
	TYPE,
	TYPE_TEXTBOX,
	TYPE_BUTTONS,
	BUTTON_NAMES,
	BUTTON_DATAS,
	TEXT_HINT,
	RECT,
	CORRECT_TEXT,
	REJECT_INCORRECT,
}

@onready var panel_container: PanelContainer = $PanelContainer
@onready var instruction_text: Label = %InstructionText
@onready var text_line: LineEdit = %TextLine
@onready var option_buttons: HFlowContainer = %OptionButtons

var _reject_incorrect := false
var _correct_texts := []


func init(options: Dictionary) -> void:
	show()
	instruction_text.visible = options.get(SHOW_TITLE, true)
	instruction_text.text = options.get(TITLE, "what to do?")
	option_buttons.hide()
	text_line.hide()
	var is_type_textline := false
	var is_type_buttons := false

	if options.get(TYPE, null) == TYPE_BUTTONS:
		is_type_buttons = true
	if options.get(BUTTON_NAMES, null) or options.get(BUTTON_DATAS, null):
		is_type_buttons = true
	if options.get(TYPE, null) == TYPE_TEXTBOX and not is_type_buttons:
		is_type_textline = true

	if is_type_buttons:
		option_buttons.show()
		var button_names: Array = options.get(BUTTON_NAMES, [])
		var button_datas: Array = options.get(BUTTON_DATAS, [])

		Math.load_reference_buttons(
				button_names,
				[option_buttons],
				_ref_button_pressed,
				_ref_received,
				{
					"custom_pass_function": _button_passthrough.bind(button_datas)
				}
		)
		option_buttons.get_child(0).grab_focus.call_deferred()

	elif is_type_textline:
		text_line.show()
		text_line.placeholder_text = options.get(TEXT_HINT, "")

		text_line.text_changed.connect(_text_changed)
		text_line.text_submitted.connect(_text_submitted)
		_correct_texts = options.get(CORRECT_TEXT, [])
		_reject_incorrect = options.get(REJECT_INCORRECT, false)

		text_line.grab_focus.call_deferred()

	assert(RECT in options, "No RECT specified.")
	panel_container.position = options.get(RECT).position
	panel_container.size = options.get(RECT).size


func _ref_button_pressed(reference: Variant) -> void:
	submitted.emit(reference)
	queue_free()


func _ref_received(reference: Variant) -> void:
	pass


func _text_submitted(text: String) -> void:
	if _reject_incorrect and not text in _correct_texts:
		return
	submitted.emit(text)
	queue_free()


func _text_changed(text: String) -> void:
	if not _correct_texts.is_empty() and text in _correct_texts:
		submitted.emit(text)
		text_line.editable = false
		create_tween().tween_interval(1.0).finished.connect(queue_free)
		return
	text_changed.emit(text)


func force_submit() -> void:
	if text_line.visible:
		submitted.emit(text_line.text)
		queue_free()
		return
	assert(not option_buttons.visible, "Trying to force submit without selection")


func _button_passthrough(data: Dictionary, button_datas: Array) -> void:
	var button: Button = data.button
	var i: int = data.nr
	#var reference: Variant = data.reference
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if button_datas.is_empty():
		button.reference = button.text
		return
	button.reference = button_datas[i]


func _exit_tree() -> void:
	DAT.free_player("user_prompt")
