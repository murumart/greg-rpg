extends EnemyAnimal


func hurt(amt: float, g: int) -> void:
	super(amt, g)
	if state == States.DEAD:
		if not DAT.get_data("fish_fought", false):
			DAT.set_data("fish_fought", true)
			if reference_to_opposing_array[0].character.health_perc() < 0.34:
				DAT.set_data("first_fish_fight_was_hard", true)
			else:
				DAT.set_data("first_fish_fight_was_hard", false)


func flee() -> void:
	super()
	if not DAT.get_data("fish_fought", false):
		DAT.set_data("fish_fought", true)
		if reference_to_opposing_array[0].character.health_perc() < 0.34:
			DAT.set_data("first_fish_fight_was_hard", true)
		else:
			DAT.set_data("first_fish_fight_was_hard", false)
