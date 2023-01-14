extends Node

# handles access to files

const GREG_USER_FOLDER_PATH := "user://greg_rpg"
const ENEMY_SCENE_PATH := "res://scenes/characters/battle_enemies/scn_enemy_%s.tscn"


func _init() -> void:
	# assure that a greg_rpg folder exists in user data
	if not DirAccess.dir_exists_absolute(GREG_USER_FOLDER_PATH):
		DirAccess.make_dir_absolute(GREG_USER_FOLDER_PATH)


func write_dict_to_file(data: Dictionary, filename : String) -> void:
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.WRITE)
	file.store_var(var_to_bytes(data))
	file.flush()


func get_dict_from_file(filename : String) -> Dictionary:
	if not FileAccess.file_exists(str(GREG_USER_FOLDER_PATH, "/", filename)):
		print("no %s file exists" % filename)
		return {}
	var file := FileAccess.open(str(GREG_USER_FOLDER_PATH, "/", filename), FileAccess.READ)
	var returnable : Dictionary = bytes_to_var(file.get_var())
	return returnable


func enemy_scene_exists(name_in_file: String) -> bool:
	if not FileAccess.file_exists(ENEMY_SCENE_PATH % name_in_file):
		return false
	return true

