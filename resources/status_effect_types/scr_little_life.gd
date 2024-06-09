func added(actor: BattleActor, _container: BattleStatusEffect) -> void:
	actor.scale = Vector2(0.2, 0.2)


func removed(actor: BattleActor, _container: BattleStatusEffect) -> void:
	actor.scale = Vector2.ONE
