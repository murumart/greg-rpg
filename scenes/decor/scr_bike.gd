extends Node2D

enum Ghosts {ALPHA, BETA, GAMMA}

@export var ghost : Ghosts = Ghosts.ALPHA

var alpha_battle_info := BattleInfo.new()


func _ready() -> void:
	if not 0 in DAT.get_data("bike_ghosts_fought", []):
		alpha_battle_info = alpha_battle_info.set_background("town").\
		set_enemies(["bike_ghost"]).\
		set_music("bike_spirit").\
		set_start_text("toute phrase en langue etrangere.").\
		set_rewards(preload("res://resources/battle_rewards/res_bike_ghost_alpha.tres"))


func _interacted() -> void:
	var fought : Array = DAT.get_data("bike_ghosts_fought", [])
	if ghost == Ghosts.ALPHA:
		if not int(Ghosts.ALPHA) in fought:
			SOL.dialogue("bike_alpha_interact_1")
			SOL.dialogue_closed.connect( 
				func speak_2():
					$AnimationPlayer.play("emerge")
					SOL.dialogue("bike_alpha_interact_2")
					SOL.dialogue_closed.connect(
						func():
							LTS.enter_battle(alpha_battle_info)
							DAT.set_data("bike_ghosts_fought", Math.reaap(fought, int(Ghosts.ALPHA)))
					)
			, CONNECT_ONE_SHOT)
