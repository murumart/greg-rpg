extends OverworldCharacter


func interacted() -> void:
	if not RunFlags.fishermen_battled_changed:
		DAT.incri("broken_fishermen_fought", battle_info.enemies.size())
		RunFlags.fishermen_battled_changed = true
	super()

