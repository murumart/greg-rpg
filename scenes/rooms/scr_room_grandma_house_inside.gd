extends Room

@onready var musicplayer := $Radio/RadioMusic
var music_last_position := 0.0
var music_last_song : String


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(_on_dialogue_closed)
	
	var fought_grandma : bool = DAT.get_data("fought_grandma", false)
	if fought_grandma:
		SOL.dialogue("grandma_fight_end")
		await SOL.dialogue_closed
		$Areas/RoomGate.force_level_transition()


func _on_radio_interaction_on_interact() -> void:
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	if musicplayer.playing:
		music_last_position = musicplayer.get_playback_position()
		musicplayer.stop()
		SND.play_song("favourable_silence" if randf() <= 0.95 else "development_hell", 3.0, {"play_from_beginning": true})
	else:
		if randf() >= 0.95:
			musicplayer.stream = load(Math.weighted_random([
				"res://music/mus_catfight.ogg",
				"res://music/mus_arent_you_excited.ogg",
				"res://music/mus_birds.ogg",
				"res://music/mus_dry_summer.ogg"
			], [1, 1, 3, 2]))
		else:
			musicplayer.stream = preload("res://music/mus_grandma_radio.ogg")
			musicplayer.seek(music_last_position)
		musicplayer.play()
		SND.play_song("", 1727)


func _on_dialogue_closed() -> void:
	if SOL.dialogue_choice == "house":
		LTS.enter_battle(
			BattleInfo.new().set_background(
				"house_inside").set_enemies(["grandma"]).set_music("lily_lesson")
					)
		SOL.dialogue_choice = ""


func _on_phone_interacted() -> void:
	if DAT.get_data("pranked", false):
		SOL.dialogue("prank_call_enough")
		return
	var number : float = DAT.get_data("nr", 0.0) * 10.0 + 1
	var call_name := "prank_call_%s"
	SOL.dialogue_box.dial_concat("prank_call_0", 1, [floorf(number)])
	SOL.dialogue("prank_call_0")
	if call_name % floorf(number) in SOL.dialogue_box.dialogues_dict.keys():
		SOL.dialogue(call_name % floorf(number))
	else:
		SOL.dialogue("prank_call_else")
	SOL.dialogue("prank_call_over")
	DAT.set_data("pranked", true)
