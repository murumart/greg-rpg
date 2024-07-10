extends Node

@export var layout_gen: GDUNGLayoutGenerator
var path: PackedInt64Array

var _path_completion := 0
var path_completion: float:
	get:
		return _path_completion / float(path.size())
var current_path_point: int = -1


func _ready() -> void:
	layout_gen.greg_entered_suite.connect(_greg_entered_suite)
	path = layout_gen.get_longest_path()
	var save: Dictionary = DAT.get_data("gdung_storyline", {})
	if save:
		_path_completion = save["path_completion"]


func _greg_entered_suite(suite: GDUNGSuiteScene) -> void:
	var suite_id := suite.suite.id
	var where_on_path := path.find(suite_id)
	if where_on_path == -1:
		return
	if where_on_path <= _path_completion:
		return
	_path_completion = where_on_path
	print(path_completion)


func _save_me() -> void:
	DAT.set_data("gdung_storyline", {
		"path_completion": _path_completion,
	})
