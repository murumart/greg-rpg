extends Node

var A : Dictionary


func _init() -> void:
	pass


func set_data(key, value) -> void:
	A[key] = value


func get_data(key: int, default = 0):
	return A.get(key, default)


func save_data() -> void:
	DIR.save_data(A)


func load_data() -> void:
	pass


func print_data() -> void:
	print(A)
