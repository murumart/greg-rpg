extends Node2D

@export var default_song: AudioStream
@export var radio_song: AudioStream
@export var silence_song: StringName

@onready var musicplayer: AudioStreamPlayer2D = $RadioMusic

var music_last_position: float


func _ready() -> void:
	$RadioInteraction.interacted.connect(_interacted)
	musicplayer.stream = default_song
	musicplayer.play()


func _interacted() -> void:
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	if musicplayer.playing:
		music_last_position = musicplayer.get_playback_position()
		musicplayer.stop()
		SND.play_song(silence_song, 3.0, {"play_from_beginning": true})
	else:
		musicplayer.stream = radio_song if radio_song else default_song
		musicplayer.play(music_last_position)
		SND.play_song("", 1727)
