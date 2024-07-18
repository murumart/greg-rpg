extends BattleEnemy

var at_gdung := false


func _ready() -> void:
	super()
	at_gdung = DAT.get_data("gdung_floor", -1) >= 1
	if not at_gdung:
		SOL.dialogue("bike_beta_battle_1")
		return
	animator.speed_scale = 1.575
	CopyGregStatsComponent.copy_stats_from(ResMan.get_character("greg"), character, 0.99)


func act() -> void:
	if at_gdung and turn > 15:
		if reference_to_team_array.size() == 1:
			SOL.dialogue("bike_ghost_gdung_enough_no_bikeghost")
			await SOL.dialogue_closed
			flee()
			return
		else:
			SOL.dialogue("bike_ghost_gdung_enough")
			SOL.dialogue_box.started_speaking.connect(_flee_at_right_time)
			SOL.dialogue_closed.connect(func():
				for actor in reference_to_team_array:
					actor.flee()
			, CONNECT_ONE_SHOT)
			return
	super()


func hurt(amt: float, g: int) -> void:
	if character.health - _hurt_damage(amt, g) <= 0 and not at_gdung:
		SOL.dialogue("bike_beta_battle_2")
		await SOL.dialogue_closed
		auto_ai = false
		ignore_my_finishes = true
		SND.play_song("")
		SOL.dialogue_open = true
		for x in 9:
			use_spirit("radiation_attack", reference_to_opposing_array[0])
			animator.stop()
			animator.clear_queue()
			animate("use_spirit")
			await create_tween().tween_interval(0.3).finished
		await create_tween().tween_interval(1.0).finished
		SOL.dialogue("bike_beta_battle_3")
		await SOL.dialogue_closed
		die()
		return
	elif character.health - _hurt_damage(amt, g) <= 0 and reference_to_team_array.size() == 1:
		SOL.dialogue("bike_ghost_gdung_defeat")
		await SOL.dialogue_closed
	super(amt, g)


func _flee_at_right_time(line: int) -> void:
	if line == 11:
		flee()
		SOL.dialogue_box.started_speaking.disconnect(_flee_at_right_time)
