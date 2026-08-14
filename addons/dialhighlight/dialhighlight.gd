@tool
extends EditorPlugin


var highlight: DialogueHighlighter


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	highlight = DialogueHighlighter.new()
	EditorInterface.get_script_editor().register_syntax_highlighter(highlight)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if is_instance_valid(highlight):
		EditorInterface.get_script_editor().unregister_syntax_highlighter(highlight)
		return
	highlight = null


class DialogueHighlighter extends EditorSyntaxHighlighter:

	var _macro_cache := PackedStringArray()


	func _get_name() -> String:
		return "gregrpgdial"
	
	
	func _get_supported_languages() -> PackedStringArray: return ["TextFile"]
	
	
	func _clear_highlighting_cache() -> void:
		_macro_cache = []
	
	
	func _create() -> EditorSyntaxHighlighter:
		return DialogueHighlighter.new()
	
	
	func _get_line_syntax_highlighting(l: int) -> Dictionary:
		var dp := DialogueParser
		var map := {}
		var te := get_text_edit()
		
		var ed := EditorInterface.get_editor_settings()
		var col_symbols: Color = ed.get_setting("text_editor/theme/highlighting/symbol_color")
		var col_keyword: Color = ed.get_setting("text_editor/theme/highlighting/keyword_color")
		var col_comment: Color = ed.get_setting("text_editor/theme/highlighting/comment_color")
		var col_strings: Color = ed.get_setting("text_editor/theme/highlighting/string_color")
		var col_control: Color = ed.get_setting("text_editor/theme/highlighting/control_flow_keyword_color")
		var col_functio: Color = ed.get_setting("text_editor/theme/highlighting/function_color")
		var col_text: Color = ed.get_setting("text_editor/theme/highlighting/text_color")
		var col_error: Color = ed.get_setting("text_editor/theme/highlighting/brace_mismatch_color")
		
		var line := te.get_line(l)
		
		map[0] = {"color": col_symbols}
		
		if line.begins_with("#"):
			map[0] = {"color": col_comment}
			return map
		if line.begins_with(dp.NEW_LINE):
			var invalid := false
			map[0] = {"color": col_text}
			var bstart := line.find("[")
			while bstart != -1:
				map[bstart] = {"color": col_symbols}
				var end := line.find("]", bstart + 1)
				if end == -1:
					invalid = true
					map[bstart] = {"color": col_error}
					break
				map[end + 1] = {"color": col_text}
				bstart = line.find("[", end + 1)
			for macro in _macro_cache:
				var ix := line.find(macro, 0)
				while ix != -1:
					map[ix] = {"color": col_strings}
					map[ix + macro.length()] = {"color": col_text}
					ix = line.find(macro, ix + macro.length())
			if invalid:
				return map
			return map
		
		for tag in [
			dp.NEW_DIAL,
		]:
			if line.begins_with(tag):
				map[0] = {"color": col_keyword}
				map[tag.length()] = {"color": col_strings}
				return map
		for tag in [
			 dp.NEW_MACRO,
		]:
			if line.begins_with(tag):
				map[0] = {"color": col_keyword}
				var name_end := line.find(" ", tag.length())
				var macro_name := line.substr(tag.length(), name_end - tag.length())
				_macro_cache.append(macro_name)
				#print("found macro `", macro_name, "`")
				map[tag.length()] = {"color": col_symbols}
				map[name_end] = {"color": col_strings}
				return map
		for tag in [
			dp.NEW_CHAR, dp.NEW_CHOICES,
			dp.NEW_EMOTION,
			dp.NEW_ITEM,
			dp.NEW_PORTRAIT_SCALE, dp.NEW_SET_DATA, dp.NEW_SILVER,
			dp.NEW_SOUND, dp.NEW_SPIRIT, dp.NEW_TXT_SPD
		]:
			if line.begins_with(tag):
				map[0] = {"color": col_functio}
				map[tag.length()] = {"color": col_symbols}
				break
		for tag in [
			dp.NEW_ALIAS,
			dp.NEW_CHOICE_LINK, dp.NEW_DATA_LINK,
			dp.NEW_INSTASKIP, dp.NEW_LOOP,
		]:
			if line.begins_with(tag):
				map[0] = {"color": col_control}
				map[tag.length()] = {"color": col_symbols}
				break
		return map
