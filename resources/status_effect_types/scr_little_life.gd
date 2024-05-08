func added(actor: BattleActor, container: BattleStatusEffect) -> void:
	actor.scale = Vector2(0.2, 0.2)


func removed(actor: BattleActor, container: BattleStatusEffect) -> void:
	actor.scale = Vector2.ONE
