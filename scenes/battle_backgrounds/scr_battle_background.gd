extends Node2D

signal beated(nr: int)

@onready var music_player : AudioStreamPlayer = $MusicPlayer
@onready var beat_timer : Timer = $BeatTimer
var bpm := 120
var beat := 0


func _ready() -> void:
	beat_timer.timeout.connect(_beat)
	
	if music_player.stream:
		bpm = music_player.stream.get_bpm()
	
	beat_timer.start(60.0 / float(bpm))
	music_player.play()


func _beat() -> void:
	beat += 1
	beated.emit(beat)
