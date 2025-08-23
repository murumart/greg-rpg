class_name SaveNodePositions extends Node

## The nodes list should NOT CHANGE during gameplay.

@export var save_these: Array[Node2D]

var key: String:
	get: return "save_node_positions_" + name + "_in_" + LTS.get_current_scene().name


func _ready() -> void:
	add_to_group("save_me")
	var list: PackedVector2Array = DAT.get_data(key, [])
	if list:
		for i in save_these.size():
			save_these[i].global_position = list[i]


func erase_saved() -> void:
	DAT.set_data(key, [])


func _save_me() -> void:
	var list: PackedVector2Array
	for node in save_these:
		list.append(node.global_position)
	DAT.set_data(key, list)
