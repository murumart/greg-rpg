extends "res://scenes/battle_backgrounds/scr_battle_background.gd"

var bpm := preload("res://music/mus_lake_battle.ogg").bpm
var bps := 60.0 / bpm
var beats_per_bar := 4.0
var bars := 0
var beats := 0.0
var flbar := 0.0
var flbeat := 0.0

@onready var animator: AnimationPlayer = $AnimationPlayer


func _process(_delta: float) -> void:
	if not is_instance_valid(SND.current_song_player):
		return
	var curr_pos := SND.current_song_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	flbar = curr_pos / (60 * beats_per_bar / bpm)
	if flbar >= bars + 1:
		new_bar()
	if flbar < bars:
		bars = -1
		new_bar()


func new_bar() -> void:
	bars += 1
	do_something()


func do_something() -> void:
	match bars:
		0: animator.play("intro")
		16: animator.play("red")
		32: animator.play("intro")
		40: animator.play("red")
		48: animator.play("sway")
