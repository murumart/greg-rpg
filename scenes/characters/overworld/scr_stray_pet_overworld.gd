extends OverworldCharacter


func interacted() -> void:
	if not RunFlags.animals_battled_changed:
		DAT.incri("stray_animals_fought", battle_info.enemies.size())
		RunFlags.animals_battled_changed = true
	super()
