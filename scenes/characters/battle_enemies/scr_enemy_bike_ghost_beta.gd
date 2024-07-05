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


func hurt(amt: float, g: int) -> void:
	if character.health - _hurt_damage(amt, g) <= 0 and not at_gdung:
		SOL.dialogue("bike_beta_battle_2")
		await SOL.dialogue_closed
		auto_ai = false
		ignore_my_finishes = true
		SND.play_song("")
		for x in 9:
			use_spirit("radiation_attack", reference_to_opposing_array[0])
			animator.stop()
			animator.clear_queue()
			animate("use_spirit")
			await create_tween().tween_interval(0.3).finished
		await create_tween().tween_interval(1.0).finished
		if not at_gdung:
			SOL.dialogue("bike_beta_battle_3")
			await SOL.dialogue_closed
	super(amt, g)

