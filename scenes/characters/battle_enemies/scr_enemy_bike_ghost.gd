extends BattleEnemy

var said_healing_line := false


func act() -> void:
	var h := false
	if turn == 0:
		SOL.dialogue("bike_ghost_welcome")
		h = true
	elif turn == 2:
		SOL.dialogue("bike_ghost_convo_1")
		h = true
	elif turn == 4:
		SOL.dialogue("bike_ghost_convo_2")
		h = true
	if character.health_perc() <= 0.5 and not said_healing_line:
		SOL.dialogue("bike_ghost_halfhealth")
		await SOL.dialogue_closed
		use_item("gummy_worm", self)
		said_healing_line = true
		h = true
	if h:
		turn_finished()
		return
	super.act()


func hurt(amount: float) -> void:
	super.hurt(amount)
	if is_zero_approx(character.health_perc()):
		SOL.dialogue("bike_ghost_defeat")
