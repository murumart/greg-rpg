extends BattleActor


func act() -> void:
	super.act()
	attack(reference_to_opposing_array.pick_random() if reference_to_actor_array.size() > 0 else null)
	print(actor_name, " acting finished!")
