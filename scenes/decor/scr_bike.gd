extends Node2D

# bikes that can be used for fast travel 
# (eventually)

enum Ghosts {ALPHA, BETA, GAMMA}

@export var ghost : Ghosts = Ghosts.ALPHA

@export var alpha_battle_info : BattleInfo

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
				func():
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
	if not int(Ghosts.ALPHA) in DAT.get_data("bike_ghosts_fought", []):
		pass
