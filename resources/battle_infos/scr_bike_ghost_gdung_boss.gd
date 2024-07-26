extends BattleInfo


func _before_load() -> void:
	super()
	var bike_ghosts_fought := DAT.get_data("bike_ghosts_fought", []) as Array
	if not 1 in bike_ghosts_fought or not 0 in bike_ghosts_fought:
		rewards = null
		enemies.clear()
		enemies.append(&"youforgotaboutme")
		start_text = "you forgot about us"
