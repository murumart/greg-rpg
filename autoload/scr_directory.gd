extends Node

const GREG_USER_FOLDER_PATH := "user://greg_rpg"


func _init() -> void:
	# assure that a greg_rpg folder exists in user data
	if not DirAccess.dir_exists_absolute(GREG_USER_FOLDER_PATH):
		DirAccess.make_dir_absolute(GREG_USER_FOLDER_PATH)


func save_data(data: Array, filename := "save.grs") -> void:
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.WRITE)
	for value in data:
		if not value: value = 0
		file.store_line(str(value))


func load_data(filename := "save.grs") -> Array:
	if not FileAccess.file_exists(str(GREG_USER_FOLDER_PATH, "/", filename)):
		return []
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.READ)
	var text := file.get_as_text()
	var split_text := text.split("\n")
	var array := []
	for string in split_text:
		if Math.num_string_type(string) == TYPE_FLOAT:
			array.append(float(string))
		elif Math.num_string_type(string) == TYPE_INT:
			array.append(int(string))
		else:
			array.append(string)
	return array


