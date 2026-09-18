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

enum UsedStatus {
	YES,
	INSP,
	}

static func static_check_all_code_files() -> void:
	var dials_dict := {}
	var used_dialogues: Dictionary[String, UsedStatus] = {}
	DialogueParser.ignore_errors = true
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_menus.dial")
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_dialogue.dial")
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_fisher_dialogue.dial")
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_status_effect_descriptions.dial")
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_res_phonecalls.dial")
	DialogueBox.load_dialogue_file(dials_dict, "res://resources/dial_insp.dial")
	DialogueParser.ignore_errors = false
	const DIAL_REGEX := r'SOL.dialogue\(\".+\"\)'
	const INSP_KEY_REGEX := r'key = \".+\"'
	const INSP_KEYS_REGEX := r'keys = Array\[String\]\(\[".+"(, ".+")*\]\)'
	var DIAL_LEN := 'SOL.dialogue("'.length()
	var KEY_LEN := 'key = "'.length()
	var dial_call_regex := RegEx.create_from_string(DIAL_REGEX)
	var insp_key_regex := RegEx.new()
	var insp_keys_regex := RegEx.new()
	insp_key_regex.compile(INSP_KEY_REGEX, true)
	insp_keys_regex.compile(INSP_KEYS_REGEX, true)
	var checkdir: Callable
	checkdir = func(path: String, used: Dictionary, this: Callable) -> void:
		var dir := DirAccess.open(path)
		if dir == null:
			print("error: ", error_string(DirAccess.get_open_error()), " path: ", path)
			return
		for dirn in dir.get_directories():
			this.call(path + "/" + dirn, used, this)
		for fn in dir.get_files():
			if fn.ends_with(".gd"):
				#print("checking ", fn)
				var txt := FileAccess.get_file_as_string(path + "/" + fn)
				assert(FileAccess.get_open_error() == OK)
				for m in dial_call_regex.search_all(txt):
					var s := m.get_string()
					s = s.substr(DIAL_LEN, s.length() - DIAL_LEN - 2)
					used[s] = UsedStatus.YES
					#print("found ", s)
				for m in insp_key_regex.search_all(txt):
					var s := m.get_string()
					s = s.substr(KEY_LEN, s.length() - KEY_LEN - 1)
					print("found maybe", s)
					used["insp_" + s] = UsedStatus.INSP
			if fn.ends_with(".tscn"):
				print("checking ", fn)
				var txt := FileAccess.get_file_as_string(path + "/" + fn)
				assert(FileAccess.get_open_error() == OK)
				for m in insp_key_regex.search_all(txt):
					var s := m.get_string()
					s = s.substr(KEY_LEN, s.length() - KEY_LEN - 1)
					print("found maybe", s)
					used["insp_" + s] = UsedStatus.INSP
				for m in insp_keys_regex.search_all(txt):
					var s := m.get_string()
					var arr: Array[String] = str_to_var(s)
					print("found maybe", s)
					for a: String in arr:
						used["insp_" + a] = UsedStatus.YES
	checkdir.call("res://", used_dialogues, checkdir)
	print(used_dialogues)
	for key: String in dials_dict.keys():
		if key.begins_with("insp_"):
			if not key in used_dialogues:
				printerr("dialogue ", key, " probably not used in inspecting anywhere")
		elif key.begins_with("fish_fact"):
			pass
		elif not key in used_dialogues:
			printerr("dialogue ", key, " not used in code anywhere")
	for s: String in used_dialogues.keys():
		var status := used_dialogues[s]
		if status == UsedStatus.YES:
			if not s in dials_dict:
				printerr("dialogue ", s, " not in dialogues anywhere")
		elif status == UsedStatus.INSP:
			if not s in dials_dict:
				printerr("dialogue ", s, " not in dialogues anywhere")
