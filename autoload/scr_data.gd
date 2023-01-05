extends Node

# handles data, saving and loading it

enum Gates {LOADING = -200}
var gate_id : int

# DATA
var A : Dictionary


func _init() -> void:
	pass


func set_data(key, value) -> void:
	A[key] = value


func get_data(key: String, default = null):
	return A.get(key, default)


func save_data(filename := "save.grs") -> void:
	save_nodes_data()
	
	var stuff := DIR.get_dict_from_file(filename)
	for k in A.keys():
		stuff[k] = A[k]
	
	DIR.write_dict_to_file(stuff, filename)


func force_data(key: String, value: Variant, filename := "save.grs") -> void:
	var stuff := DIR.get_dict_from_file(filename)
	
	stuff[key] = value
	DIR.write_dict_to_file(stuff, filename)
	
	print("forced key %s and value %s to file %s" % [key, value, filename])


func save_nodes_data() -> void:
	print("node saving start.")
	var saveables := get_tree().get_nodes_in_group("save_me")
	for node in saveables:
		if is_instance_valid(node) and node.has_method("_save_me"):
			node._save_me()
	print("node saving end.")


func load_data(filename := "save.grs") -> void:
	var loaded := DIR.get_dict_from_file(filename)
	if loaded.size() < 1: print("no data to load."); return
	
	for k in loaded.keys():
		A[k] = loaded[k]
	
	var room_to_load : String = loaded.get("current_room", "test")
	gate_id = Gates.LOADING
	LTS.change_scene_to(LTS.ROOM_SCENE_PATH % room_to_load)
	SOL.fade_screen(Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)


func print_data() -> void:
	print(A)


func capture_player() -> void:
	var players : Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].state = PlayerOverworld.States.NOT_FREE_MOVE


func free_player() -> void:
	var players : Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].state = PlayerOverworld.States.FREE_MOVE

