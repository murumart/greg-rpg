extends BattleEnemy

var said_healing_line := false
var enemy_powerful := false
var dead := false


func act() -> void:
	var h := false
	var y := false
	if turn == 0:
		if character.health_perc() < 0.8:
			enemy_powerful = true
		SOL.dialogue("bike_ghost_welcome" if not enemy_powerful else "bike_ghost_powerfulenemy_1")
		if enemy_powerful: add_status_effect_s(&"speed", 16, 16)
		h = true
	elif turn == 2:
		SOL.dialogue("bike_ghost_convo_1" if not enemy_powerful else "bike_ghost_powerfulenemy_2")
		if enemy_powerful: add_status_effect_s(&"speed", 32, 16)
		h = true
	elif turn == 4:
		SOL.dialogue("bike_ghost_convo_2" if not enemy_powerful else "bike_ghost_powerfulenemy_3")
		if enemy_powerful and character.magic < 99:
			SOL.dialogue("bike_ghost_powerfulenemy_outofmagic")
		if enemy_powerful:
			add_status_effect_s(&"speed", 64, 16)
			hurting_spirits.append("radiation_attack")
		vaimulembesus = 0.98
		h = true
	if character.health_perc() <= 0.5 and not said_healing_line:
		SOL.dialogue("bike_ghost_halfhealth")
		await SOL.dialogue_closed
		use_item("gummy_worm", self)
		said_healing_line = true
		h = true
		y = true
	if h:
		if not y: turn_finished()
		return
	super.act()


func hurt(amount: float, gnd: int) -> void:
	if dead: return
	super.hurt(amount, gnd)
	if is_zero_approx(character.health_perc()):
		dead = true
		SOL.dialogue("bike_ghost_defeat")
		SOL.dialogue_box.changed_dialogue.connect(
			func():
				use_spirit("radiation_attack", reference_to_opposing_array[0])
		, CONNECT_ONE_SHOT)
