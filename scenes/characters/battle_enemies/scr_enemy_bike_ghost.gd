extends BattleEnemy

var said_healing_line := false
var powerful_progress := 1
var dead := false
var at_gdung := false
var alone := true


func _ready() -> void:
	super ()
	at_gdung = DAT.get_data("gdung_floor", -1) >= 1
	if at_gdung:
		animator.speed_scale = 2.57166
		CopyGregStatsComponent.copy_stats_if_im_less(ResMan.get_character("greg"), character, 0.95)
		await get_tree().process_frame # because other enemies haven't been added yet
		if reference_to_team_array.size() > 1:
			SOL.dialogue("bike_ghost_gdung_1")
			alone = false
		else:
			SOL.dialogue("bike_ghost_gdung_solo")


func act() -> void:
	if not at_gdung:
		_act_normal()
		return
	_act_gdung()


func _act_normal() -> void:
	if turn == 0:
		if character.health_perc() <= 0.75:
			add_status_effect_s(&"speed", 32, 16)
		SOL.dialogue("bike_ghost_welcome")


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


func hurt(amount: float, gnd: int) -> void:
	if at_gdung:
		if character.health - _hurt_damage(amount, gnd) <= 0:
			if reference_to_team_array.size() == 1 and not alone:
				SOL.dialogue("bike_ghost_gdung_defeat")
				await SOL.dialogue_closed
			die()
			return
		super (amount, gnd)
		return
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
