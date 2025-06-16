extends Room

@onready var musicplayer := $Radio/RadioMusic
var music_last_position := 0.0
var music_last_song: String
@export_range(-1, 10) var prank_call_force := -1
@onready var things_to_delete := [$Grandma, $Decor/Sprite2D18, $Decor/Sprite2D19,
	$Decor/Sprite2D15, $Decor/Sprite2D20, $Decor/Sprite2D5, $Decor/Flower1, $Decor/Flower2,
	$Decor/Flower3, $Decor/Flower4, $Decor/Flower5, $Decor/Flower6, $Decor/Flower7,
	$Decor/Flower8, $Decor/Flower9, $Cats]
@onready var door_area: Area2D = $Areas/DoorArea


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(_on_dialogue_closed)
	if ResMan.get_character("greg").level >= DAT.GDUNG_LEVEL:
		things_to_delete.map(func(a): a.queue_free())
		if DAT.get_data("gdung_floor", 0) >= 3:
			door_area.destination = &"after_gdung"
		door_area.destination = &"dungeon"
		return
	# long grandma lol
	if Math.inrange(DAT.get_data("nr", 0), 0.15, 0.16):
		$Grandma/AnimatedSprite2D.scale.y = 4.875
		$Grandma.default_lines.clear()
		$Grandma.default_lines.append(&"grandma_fight_1")
		DAT.incrf("nr", 0.02)


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
	var number: int = int(DAT.get_data("nr", 0.0) * 10.0 + 1)
	if prank_call_force > -1:
		number = prank_call_force
	var call_name := "prank_call_%s"
	if number == 10:
		if musicplayer.playing:
			musicplayer.stop()
	SOL.dialogue_box.dial_concat("prank_call_0", 1, [floorf(number)])
	SOL.dialogue("prank_call_0")
	if call_name % floorf(number) in SOL.dialogue_box.dialogues_dict.keys():
		SOL.dialogue(call_name % floorf(number))
	else:
		SOL.dialogue("prank_call_else")
	SOL.dialogue("prank_call_over")
	DAT.set_data("pranked", true)
