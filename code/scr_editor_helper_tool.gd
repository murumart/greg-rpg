@tool
class_name EditorHelperTool extends Node

@export var call_auto: bool:
	set(to):
		auto()


func _ready() -> void:
	if not Engine.is_editor_hint() and not OS.has_feature("editor"):
		queue_free()
		return
	auto()


func auto() -> void:
	if not Engine.is_editor_hint() and not OS.has_feature("editor"):
		return
	set_project_version()


func set_project_version() -> void:
	print("setting version")
	var DAT_SCRIPT := load("res://autoload/scr_data.gd")
	ProjectSettings.set_setting("application/config/version", DAT_SCRIPT.version_str())
	ProjectSettings.save()
