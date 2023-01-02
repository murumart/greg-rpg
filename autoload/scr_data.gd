extends Node

enum {CURRENT_ROOM, PLAYER_X_POS, PLAYER_Y_POS, MAX_VALUE, }
var saveable_values : Array


func _init() -> void:
	saveable_values.resize(MAX_VALUE)


func set_data(what: int, to) -> void:
	assert(what < saveable_values.size() and what > -1)
	saveable_values[what] = to


func get_data(where: int, default):
	assert(where < saveable_values.size() and where > -1)
	return saveable_values[where]


func save_data() -> void:
	DIR.save_data(saveable_values)


func load_data() -> void:
	pass
