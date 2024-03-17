func turn(actor: BattleActor, container: BattleStatusEffect) -> void:
	# coughing damage is applied by a separate battle actor because why not
	var cougher := BattleActor.new()
	cougher.character = Character.new()
	cougher.character.attack = container.strength * 2
	actor.add_child(cougher)
	cougher.attack(actor)
	SND.play_sound(preload("res://sounds/spirit/airspace_violation.ogg"), {"volume": -3})
	cougher.queue_free()
