@tool
class_name EditorHelperTool extends Node

@export var call_auto: bool:
	set(to):
		auto()


func _ready() -> void:
	if not Engine.is_editor_hint() or DIR.standalone():
		queue_free()
		return
	auto()


func auto() -> void:
	if not Engine.is_editor_hint() or DIR.standalone():
		return
	set_project_version()


func set_project_version() -> void:
	var DAT_SCRIPT := load("res://autoload/scr_data.gd")
	if not ProjectSettings.get_setting("application/config/version") == DAT_SCRIPT.version_str():
		ProjectSettings.set_setting("application/config/version", DAT_SCRIPT.version_str())
		print("setting version")
	ProjectSettings.save()
