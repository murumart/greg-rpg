extends Room

@onready var musicplayer := $Radio/RadioMusic


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(_on_dialogue_closed)
	
	var fought_grandma : bool = DAT.get_data("fought_grandma", false)
	if fought_grandma:
		SOL.dialogue("grandma_fight_end")
		await SOL.dialogue_closed
		$Areas/RoomGate.force_level_transition()


func _on_radio_interaction_on_interact() -> void:
	SND.play_sound(preload("res://sounds/snd_misc_click.ogg"))
	if musicplayer.playing:
		musicplayer.stop()
		SND.play_song("favourable_silence" if randf() <= 0.95 else "development_hell", 3.0, {"play_from_beginning": true})
	else:
		if randf() >= 0.95:
			musicplayer.stream = load([
				"res://music/mus_catfight.ogg",
				"res://music/mus_arent_you_excited.ogg",
				"res://music/mus_birds.ogg",
				"res://music/mus_birds.ogg",
				"res://music/mus_dry_summer.ogg"
			].pick_random())
		else: musicplayer.stream = preload("res://music/mus_grandma_radio.ogg")
		musicplayer.play()
		SND.play_song("", 1727)


func _on_dialogue_closed() -> void:
	if SOL.dialogue_choice == "house":
		LTS.enter_battle(
			BattleInfo.new().set_background(
				"house_inside").set_enemies(["grandma"]).set_music("lily_lesson")
					)
		SOL.dialogue_choice = ""

