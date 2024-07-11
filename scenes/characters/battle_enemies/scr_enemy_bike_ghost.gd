extends BattleEnemy

var said_healing_line := false
var enemy_powerful := false
var powerful_progress := 1
var dead := false
var at_gdung := false


func _ready() -> void:
	super()
	at_gdung = DAT.get_data("gdung_floor", -1) >= 1
	if at_gdung:
		SOL.dialogue("bike_ghost_gdung_1")
		animator.speed_scale = 2.57166
		CopyGregStatsComponent.copy_stats_from(ResMan.get_character("greg"), character, 0.95)


func act() -> void:
	if not at_gdung:
		_act_normal()
		return
	_act_gdung()


func _act_normal() -> void:
	if turn == 0:
		if character.health_perc() <= 0.75:
			enemy_powerful = true
			add_status_effect_s(&"speed", 16, 16)
		SOL.dialogue("bike_ghost_welcome" if not enemy_powerful else "bike_ghost_powerfulenemy_1")
	if enemy_powerful:
		await hnnng_____the_power()
		super.act()
		return

	if turn == 2:
		SOL.dialogue("bike_ghost_convo_1")
	elif turn == 4:
		SOL.dialogue("bike_ghost_convo_2")
	if character.health_perc() <= 0.5 and not said_healing_line:
		SOL.dialogue("bike_ghost_halfhealth")
		await SOL.dialogue_closed
		use_item("gummy_worm", self)
		said_healing_line = true
		return
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	super.act()


func _act_gdung() -> void:
	super.act()


func hnnng_____the_power() -> void:
	if character.health_perc() <= 0.5 and powerful_progress <= 1:
		SOL.dialogue("bike_ghost_powerfulenemy_2")
		add_status_effect_s(&"speed", 48, 16)
		powerful_progress += 1
	if character.health_perc() <= 0.4 and powerful_progress <= 2:
		SOL.dialogue("bike_ghost_powerfulenemy_3")
		hurting_spirits.append("radiation_attack")
		add_status_effect_s(&"speed", 72, 16)
		powerful_progress += 1
		if character.magic < 99:
			SOL.dialogue("bike_ghost_powerfulenemy_outofmagic")
	if SOL.dialogue_open:
		await SOL.dialogue_closed


func hurt(amount: float, gnd: int) -> void:
	if at_gdung:
		if character.health - _hurt_damage(amount, gnd) <= 0:
			if reference_to_team_array.size() == 1:
				SOL.dialogue("bike_ghost_gdung_defeat")
				await SOL.dialogue_closed
		super(amount, gnd)
		return
	if enemy_powerful:
		hnnng_____the_power()
	if dead:
		return
	super.hurt(amount, gnd)
	if is_zero_approx(character.health_perc()):
		dead = true
		SOL.dialogue("bike_ghost_defeat")
		SOL.dialogue_box.changed_dialogue.connect(
			func():
				use_spirit("radiation_attack", reference_to_opposing_array[0])
		, CONNECT_ONE_SHOT)
