extends TileMap

@onready var current_room := DAT.get_data("forest_depth") as int



func _ready() -> void:
	if DAT.get_data("forest_save", {}).get("pond_" + str(current_room), false):
		$EnemyEncounterArea.queue_free()
		return
	$EnemyEncounterArea.player = get_tree().get_first_node_in_group("players")


func _save_me() -> void:
	var area := get_node_or_null("EnemyEncounterArea")
	if not is_instance_valid(area):
		return
	var battled: bool = area.battles_initiated > 0
	DAT.get_data("forest_save", {})["pond_" + str(current_room)] = battled
