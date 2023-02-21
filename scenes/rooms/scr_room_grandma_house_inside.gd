extends Room

@onready var musicplayer := $Radio/RadioMusic


func _ready() -> void:
	super._ready()


func _on_radio_interaction_on_interact() -> void:
	SND.play_sound(preload("res://sounds/snd_misc_click.ogg"))
	if musicplayer.playing:
		musicplayer.stop()
		SND.play_song("favourable_silence" if randf() <= 0.95 else "development_hell", 3.0, {"play_from_beginning": true})
	else:
		if randf() >= 0.95:
			musicplayer.stream = load([
				"res://music/mus_bike_spirit.ogg",
				"res://music/mus_arent_you_excited.ogg",
				"res://music/mus_birds.ogg",
				"res://music/mus_dry_summer.ogg"
			].pick_random())
		else: musicplayer.stream = preload("res://music/mus_grandma_radio.ogg")
		musicplayer.play()
		SND.play_song("", 1727)
