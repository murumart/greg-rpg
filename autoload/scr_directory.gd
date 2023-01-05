extends Node

const GREG_USER_FOLDER_PATH := "user://greg_rpg"


func _init() -> void:
	# assure that a greg_rpg folder exists in user data
	if not DirAccess.dir_exists_absolute(GREG_USER_FOLDER_PATH):
		DirAccess.make_dir_absolute(GREG_USER_FOLDER_PATH)


func save_data(data, filename := "save.grs") -> void:
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.WRITE)
	var meh := PackedByteArray()
	meh.resize(int(pow(2, 16) -1))
	meh.encode_var(0, data)
	file.store_buffer(meh)
	file.flush()
	print("wrote data to wile ", filename)


func load_data(filename := "save.grs") -> Dictionary:
	if not FileAccess.file_exists(str(GREG_USER_FOLDER_PATH, "/", filename)):
		print("no savefile exists")
		return {}
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.READ)
	var returnable := {}
	var meh := file.get_buffer(int(pow(2, 16) -1))
	returnable = meh.decode_var(0)
	print("loaded from file ", filename)
	return returnable


