@tool
class_name EditorHelperTool extends Node

@export_tool_button("Update project version") var spv := set_project_version
@export_tool_button("Static Check") var sck := static_check_all_code_files


func _ready() -> void:
	if not Engine.is_editor_hint() or not OS.has_feature("editor"):
		sck = static_check_all_code_files
		queue_free()
		return
	auto()


func auto() -> void:
	if not Engine.is_editor_hint() or not OS.has_feature("editor"):
		return
	set_project_version()


func set_project_version() -> void:
	var DAT_SCRIPT := load("res://autoload/scr_data.gd")
	if not ProjectSettings.get_setting("application/config/version") == DAT_SCRIPT.version_str():
		ProjectSettings.set_setting("application/config/version", DAT_SCRIPT.version_str())
		print("setting version")
	ProjectSettings.save()


static func static_check_all_code_files(path := "res://", dials_dict := {}) -> void:
	var dir := DirAccess.open(path)
	if dials_dict.is_empty():
		DialogueParser.ignore_errors = true
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_menus.dial")
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_dialogue.dial")
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_fisher_dialogue.dial")
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_status_effect_descriptions.dial")
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_res_phonecalls.dial")
		DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_insp.dial")
		DialogueParser.ignore_errors = false
	if dir == null:
		print("error: ", error_string(DirAccess.get_open_error()), " path: ", path)
		return
	for dirn in dir.get_directories():
		static_check_all_code_files(path + "/" + dirn, dials_dict)
	const DIAL_REGEX := r'SOL.dialogue\(\".+\"\)'
	var DIAL_LEN := 'SOL.dialogue("'.length()
	var regex := RegEx.create_from_string(DIAL_REGEX)
	for fn in dir.get_files():
		if not fn.ends_with(".gd"): continue
		print("checking ", fn)
		var txt := FileAccess.get_file_as_string(path + "/" + fn)
		assert(FileAccess.get_open_error() == OK)
		for m in regex.search_all(txt):
			var s := m.get_string()
			s = s.substr(DIAL_LEN, s.length() - DIAL_LEN - 2)
			#print("found ", s)
			if not s in dials_dict:
				printerr("dialogue ", s, " not in dialogues anywhere")
