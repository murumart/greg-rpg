func turn(actor: BattleActor, container: BattleStatusEffect) -> void:
	for x in actor.reference_to_opposing_array:
		x.heal(container.strength * 3.5)
