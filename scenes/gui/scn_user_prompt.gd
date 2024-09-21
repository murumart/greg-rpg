class_name UserPrompt extends Control

signal submitted(data: Variant)

enum {
	SHOW_TITLE,
	TYPE,
	TYPE_TEXTBOX,
	TYPE_BUTTONS,
	BUTTON_NAMES,
	BUTTON_DATAS,
	TEXT_HINT,
	RECT
}

var _LOAD_REF_OPTS := {
	"custom_pass_function": _button_passthrough
}

@onready var panel_container: PanelContainer = $PanelContainer
@onready var instruction_text: Label = %InstructionText
@onready var text_line: LineEdit = %TextLine
@onready var option_buttons: HFlowContainer = %OptionButtons


func init(options: Dictionary) -> void:
	show()
	instruction_text.visible = options.get(SHOW_TITLE, true)
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
				_LOAD_REF_OPTS
		)
	
	elif is_type_textline:
		text_line.show()
		text_line.placeholder_text = options.get(TEXT_HINT, "")
	
	


func _ref_button_pressed(reference: Variant) -> void:
	pass


func _ref_received(reference: Variant) -> void:
	pass


func _button_passthrough(data: Dictionary) -> void:
	var button: Button = data.button
	#var i: int = data.nr
	#var reference: Variant = data.reference
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
