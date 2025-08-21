extends TileMap

var current_room: int:
	get: return DAT.get_data("forest_depth", 0) as int



func _ready() -> void:
	if DAT.get_data("forest_save", {}).get(_key(), false):
		print("removing pond ", self)
		$EnemyEncounterArea.queue_free()
		return
	$EnemyEncounterArea.player = get_tree().get_first_node_in_group("players")


func _save_me() -> void:
	var area := get_node_or_null(^"EnemyEncounterArea")
	if not is_instance_valid(area):
		return
	var battled: bool = area.battles_initiated > 0
	# multiple ponds get different results in one room!
	DAT.get_data("forest_save", {})[_key()] = battled or DAT.get_data("forest_save", {}).get(_key(), false)


func _key() -> String:
	return "pond_" + str(current_room)
