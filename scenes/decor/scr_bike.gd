extends Node2D

# bikes that can be used for fast travel 
# (eventually)

enum Ghosts {ALPHA, BETA, GAMMA}

@export var ghost : Ghosts = Ghosts.ALPHA

var alpha_battle_info := BattleInfo.new()

@export var player : PlayerOverworld


func _ready() -> void:
	load_ghosts()
	
	await get_tree().process_frame
	await get_tree().process_frame
	if LTS.gate_id == LTS.GATE_BIKE_TRAVEL:
		if player:
			player.global_position = $SpawnPoint.global_position


func _interacted() -> void:
	var fought : Array = DAT.get_data("bike_ghosts_fought", [])
	if ghost == Ghosts.ALPHA:
		if not int(Ghosts.ALPHA) in fought:
			SND.play_song("")
			SOL.dialogue("bike_alpha_interact_1")
			SOL.dialogue_closed.connect( 
				func speak_2():
					$AnimationPlayer.play("emerge")
					SND.play_song("bike_spirit", 0.20, {pitch_scale = 0.75, volume = -5})
					SND.play_sound(load("res://sounds/spirit/bikeghost/snd_alpha_appear.ogg"), {bus = "ECHO"})
					SOL.dialogue("bike_alpha_interact_2")
					SOL.dialogue_closed.connect(
						func():
							LTS.enter_battle(alpha_battle_info)
							DAT.appenda("bike_ghosts_fought", int(Ghosts.ALPHA))
					)
			, CONNECT_ONE_SHOT)
		else:
			SOL.dialogue("bike_ghost_afterdefeat")
	# elif...


func load_ghosts() -> void:
	if not 0 in DAT.get_data("bike_ghosts_fought", []):
		alpha_battle_info = alpha_battle_info.set_background("town").\
		set_enemies(["bike_ghost"]).\
		set_music("bike_spirit").\
		set_start_text("toute phrase en langue etrangere.").\
		set_rewards(preload("res://resources/battle_rewards/res_bike_ghost_alpha.tres"))
