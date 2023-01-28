extends Node

# handles access to files

const GREG_USER_FOLDER_PATH := "user://greg_rpg"
const ENEMY_SCENE_PATH := "res://scenes/characters/battle_enemies/scn_enemy_"
const ROOM_SCENE_PATH := "res://scenes/rooms/scn_room_"
const BATTLE_BACKGROUND_SCENE_PATH := "res://scenes/battle_backgrounds/scn_"
const TSCN := ".tscn"
const SCN := ".scn"


func _init() -> void:
	print("DIR init")
	print("project is standalone" if standalone() else "project is editor version")
	# assure that a greg_rpg folder exists in user data
	if not DirAccess.dir_exists_absolute(GREG_USER_FOLDER_PATH):
		DirAccess.make_dir_absolute(GREG_USER_FOLDER_PATH)


func standalone() -> bool:
	return OS.has_feature("standalone")


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
	var path := enemy_scene_path(name_in_file)
	print(path)
	if FileAccess.file_exists(path):
		return true
	return false


func file_exists(path) -> bool:
	if FileAccess.file_exists(path):
		return true
	return false


func enemy_scene_path(name_in_file: String) -> String:
	return str((ENEMY_SCENE_PATH + name_in_file), SCN if standalone() else TSCN)


func room_scene_path(id: String) -> String:
	return str((ROOM_SCENE_PATH + id), SCN if standalone() else TSCN)


func battle_background_scene_path(id: String) -> String:
	return str((BATTLE_BACKGROUND_SCENE_PATH + id), SCN if standalone() else TSCN)


func get_dialogue_file() -> String:
	var file := FileAccess.open("res://resources/res_dialogue.txt", FileAccess.READ)
	return file.get_as_text()
