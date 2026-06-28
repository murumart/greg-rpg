extends BattleEnemy

var said_healing_line := false
var powerful_progress := 1
var dead := false
var alone := true


func _ready() -> void:
	super ()


func act() -> void:
	_act_normal()


func _act_normal() -> void:
	if turn == 0:
		if character.health_perc() <= 0.65:
			add_status_effect_s(&"speed", 32, 16)
		SOL.dialogue("bike_ghost_welcome")


	if turn == 2:
		SOL.dialogue("bike_ghost_convo_1")
	elif turn == 4:
		SOL.dialogue("bike_ghost_convo_2")
	if character.health_perc() <= 0.5 and not said_healing_line:
		SOL.dialogue("bike_ghost_halfhealth")
		await SOL.dialogue_closed
		use_item("gummy_worm", self )
		said_healing_line = true
		return
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	super.act()


func hurt(amount: float, gnd: int) -> void:
	if dead:
		return
	if character.health - _hurt_damage(amount, gnd) <= 0:
		dead = true
		auto_ai = false
		ignore_my_finishes = true
		animate("death")
		SND.play_song("")
		SOL.dialogue("bike_ghost_defeat")
		await SOL.dialogue_closed
		SOL.dialogue_open = true
		use_spirit("radiation_attack", reference_to_opposing_array[0])
		await Math.timer(5.0)
		SOL.dialogue_open = false
		die()
		return
	super.hurt(amount, gnd)
