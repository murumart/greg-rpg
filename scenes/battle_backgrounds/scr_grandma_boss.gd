extends "res://scenes/battle_backgrounds/scr_battle_background.gd"

@onready var sprite: Sprite2D = $Sprite2D

func _process(_delta: float) -> void:
	sprite.material["shader_parameter/wow"] = 0.0
	var song := SND.current_song_player
	if not is_instance_valid(song):
		return
	var playback_pos := song.get_playback_position()
	if playback_pos >= 83.0:
		sprite.material["shader_parameter/wow"] = 1.0
