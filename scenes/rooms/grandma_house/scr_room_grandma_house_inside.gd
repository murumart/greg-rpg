extends Room

@onready var musicplayer := $Radio/RadioMusic
var music_last_position := 0.0
var music_last_song: String
@export_range(-1, 10) var prank_call_force := -1
@onready var door_area: Area2D = $Door/DoorArea

@export var radio_song: AudioStreamRandomizer
@export var radio_other_song: AudioStreamRandomizer


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(func() -> void:
		if SOL.dialogue_choice == "house":
			LTS.enter_battle(
				BattleInfo.new().set_background(
						"house_inside").set_enemies(["grandma"]).set_music("lily_lesson")
				)
			SOL.dialogue_choice = ""
	)

	if ResMan.get_character("greg").level >= DAT.GDUNG_LEVEL:
		get_tree().get_nodes_in_group("empty_delete").map(func(a): a.queue_free())
		if DAT.get_data("gdung_floor", 0) >= 3:
			door_area.destination = &"after_gdung"
		door_area.destination = &"dungeon"
		return
	# long grandma lol
	if Math.inrange(DAT.get_data("nr", 0), 0.665, 0.67) and not DAT.get_data("sscyr", false):
		DAT.set_data("sscyr", true)
		$Grandma/AnimatedSprite2D.scale.y = 4.875
		$Grandma.default_lines.clear()
		$Grandma.default_lines.append(&"grandma_fight_1")


func _on_radio_interaction_on_interact() -> void:
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	if musicplayer.playing:
		music_last_position = musicplayer.get_playback_position()
		musicplayer.stop()
		SND.play_song("favourable_silence", 3.0, {"play_from_beginning": true})
	else:
		musicplayer.stream = radio_song
		musicplayer.play(music_last_position)
		SND.play_song("", 1727)


func _on_phone_interacted() -> void:
	if DAT.get_data("pranked", false):
		SOL.dialogue("prank_call_enough")
		return
	var number: int = int(DAT.get_data("nr", 0.0) * 10.0 + 1)
	if prank_call_force > -1:
		number = prank_call_force
	var call_name := "prank_call_%s"
	if number == 10:
		if musicplayer.playing:
			musicplayer.stop()
	SOL.dialogue_box.dial_concat("prank_call_0", 1, [number])
	SOL.dialogue("prank_call_0")
	if call_name % number in SOL.dialogue_box.dialogues_dict.keys():
		SOL.dialogue(call_name % number)
	else:
		SOL.dialogue("prank_call_else")
	SOL.dialogue("prank_call_over")
	DAT.set_data("pranked", true)
