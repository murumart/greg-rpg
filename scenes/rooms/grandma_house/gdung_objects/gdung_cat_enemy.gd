extends Node2D

@onready var grandma_housecat: OverworldCharacter = $GrandmaHousecat


func _ready() -> void:
	grandma_housecat.inspected.connect(_on_attack)
	var saved_cats := DAT.get_data("gdung_saved_cats", {}) as Dictionary
	if not saved_cats:
		return
	if saved_cats.get(get_save_key(), {}).get("fought", false):
		queue_free()
		return


func _on_attack() -> void:
	var saved_cats := DAT.get_data("gdung_saved_cats", {}) as Dictionary
	saved_cats[get_save_key()] = {"fought": true}
	DAT.set_data("gdung_saved_cats", saved_cats)


func get_save_key() -> StringName:
	return ("gdung_cat_floor_"
			+ str(DAT.get_data("gdung_floor", 0))
			+ "_pos_" + str(global_position))
