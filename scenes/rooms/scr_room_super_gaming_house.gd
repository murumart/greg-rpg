extends Room


func _ready() -> void:
	super._ready()
	$EntertainmentSystem/ComputerInteract.on_interact.connect(_on_computer_interacted)
	if LTS.gate_id == LTS.GATE_EXIT_GAMING:
		after_game_dial()


func _on_computer_interacted() -> void:
	SOL.dialogue("ph_computer")
	SOL.dialogue_closed.connect(
		func():
			if SOL.dialogue_choice == &"yes":
				SND.play_song("")
				if DAT.get_data("pennistongs_played", 0) == 0:
					SND.play_sound(preload("res://sounds/pennistong/gaming_start.ogg"))
					LTS.level_transition("res://scenes/pennistong/penni_stong.tscn",
					{
						"start_color": Color(1, 1, 1, 0),
						"end_color": Color.WHITE,
						"fade_time": 3.2,
						"abrupt_end": true
					})
				else:
					LTS.level_transition("res://scenes/pennistong/penni_stong.tscn")
	, CONNECT_ONE_SHOT)


func after_game_dial() -> void:
	var games_played : int = DAT.get_data("pennistongs_played", 0)
	if games_played == 1:
		SOL.dialogue("after_pennistong_first")
	if DAT.get_data("last_pennistong_game_win", true):
		SOL.dialogue("after_pennistong_win")
	else:
		SOL.dialogue("after_pennistong_lose")
	SOL.dialogue("after_pennistong_finish")
