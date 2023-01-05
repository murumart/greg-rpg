extends Node

var A : Dictionary


func _init() -> void:
	pass


func set_data(key, value) -> void:
	A[key] = value


func get_data(key: int, default = 0):
	return A.get(key, default)


func save_data() -> void:
	save_nodes_data()
	
	DIR.save_data(A)


func save_nodes_data() -> void:
	print("node saving start.")
	var saveables := get_tree().get_nodes_in_group("save_me")
	for node in saveables:
		if is_instance_valid(node) and node.has_method("_save_me"):
			node._save_me()
	print("node saving end.")


func load_data(filename := "save.grs") -> void:
	var loaded := DIR.load_data(filename)
	if loaded.size() < 1: print("no data to load."); return
	
	var room_to_load : String = loaded.get("current_room", "")
	


func print_data() -> void:
	print(A)
