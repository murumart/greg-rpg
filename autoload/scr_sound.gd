extends Node

# handles playing sounds and music
# copied over from old Greg

var current_song_player : AudioStreamPlayer
var current_song : Dictionary
var old_song : Dictionary
var previously_played_song_key : String = ""
var current_song_key : String = ""
var list := SongsList.new() # stored data about songs

const DEFAULT_VOLUME := 0.0
const DEFAULT_WAIT_SPEED := 1.0

const MAX_SOUNDS_PLAYING := 66
var playing_sounds := []

var sound_clear_timer := Timer.new()


func _init() -> void:
	pass


func _ready() -> void:
	add_child(sound_clear_timer)
	sound_clear_timer.connect("timeout", _on_sound_clear_timer_timeout)
	sound_clear_timer.start()
	sound_clear_timer.process_mode = Node.PROCESS_MODE_ALWAYS # sounds cleanup shan't pause


func play_song(song: String, fade_speed := 1.0, options := {}):
	var _save_audio_position : bool = options.get("save_audio_position", true)
	var play_from_beginning : bool = options.get("play_from_beginning", false)
	var pitch_scale : float = options.get("pitch_scale", 1.0)
	var volume_override := "volume" in options
	var volume : float = options.get("volume", DEFAULT_VOLUME)
	var bus : String = options.get("bus", "Music")
	var trans_type : int = options.get("trans_type", Tween.TRANS_QUAD)
	var fade_in_ease_type : int = options.get("fade_in_ease_type", Tween.EASE_OUT)
	var _fade_out_ease_type : int = options.get("fade_out_ease_type", Tween.EASE_IN)
	var start_volume : float = options.get("start_volume", -80.0)
	var skip_to : float = options.get("skip_to", 0.0)
	var loop_override := "loop" in options
	var loop : bool = options.get("loop", true)
	
	var song_dict : Dictionary = list.songs.get(song, {})
	
	# if the music requested is the same as current music, do nothing
	if current_song.size() > 0 and song in list.songs and current_song.get("title") == song_dict.get("title", ""):
		return
	
	previously_played_song_key = current_song_key
	current_song_key = song
	old_song = current_song
	current_song = {}
	
	fade_out_song_player(current_song_player, fade_speed, options)
	
	# silence
	if song_dict.keys().size() < 1:
		return
	
	var new_audio_player := AudioStreamPlayer.new()
	current_song_player = new_audio_player
	new_audio_player.name = str("music_" + song)
	playing_sounds.append(new_audio_player)
	add_child(new_audio_player)
	var audio_stream : AudioStream = load(song_dict.get("link"))
	audio_stream.loop = song_dict.get("loop", true)
	if loop_override: audio_stream.loop = loop
	new_audio_player.stream = audio_stream
	new_audio_player.volume_db = start_volume
	new_audio_player.pitch_scale = song_dict.get("default_pitch", 1.0) * pitch_scale
	new_audio_player.bus = bus
	current_song = list.songs[song]
	
	new_audio_player.play()
	if not play_from_beginning:
		new_audio_player.seek(current_song.get("progress", 0.01))
		if skip_to != 0.0:
			new_audio_player.seek(skip_to)
	var tween := create_tween().set_ease(fade_in_ease_type).set_trans(trans_type)
	var volume_to : float = song_dict.get("default_volume", DEFAULT_VOLUME) if not volume_override else volume
	tween.tween_property(new_audio_player, "volume_db", volume_to, DEFAULT_WAIT_SPEED/float(fade_speed))


func fade_out_song_player(player, fade_speed := 1.0, options := {}):
	if not (is_instance_valid(player) and player.playing): return
	player = player as AudioStreamPlayer
	
	var fade_out_ease_type = options.get("fade_out_ease_type", Tween.EASE_IN)
	var trans_type = options.get("trans_type", Tween.TRANS_QUAD)
	
	var tween := create_tween().set_ease(fade_out_ease_type).set_trans(trans_type)
	tween.tween_property(player, "volume_db", -80.0, DEFAULT_WAIT_SPEED/float(fade_speed))
	tween.step_finished.connect(_on_fadeout_tween_step_finished.bind(player, options), CONNECT_ONE_SHOT)


func _on_fadeout_tween_step_finished(_int_stupid: int, player, options := {}):
	# _int_stupid is provided by the tween.step_finished signal, I don't need it for anything
	var do_save_audio_position = options.get("save_audio_position", true)
	
	if not (is_instance_valid(player) and player.playing): return
	player = player as AudioStreamPlayer
	
	var _err = save_audio_position(player, old_song) if do_save_audio_position else null
	player.stop()
	player.queue_free()


func get_music_playback_position():
	if not is_instance_valid(current_song_player):
		printerr("current song player invalid")
		return
	return current_song_player.get_playback_position()


func save_audio_position(player: AudioStreamPlayer, song: Dictionary):
	if not is_instance_valid(player): return
	var position := player.get_playback_position()
	song["progress"] = position


func play_sound(sound: AudioStream, options := {}):
	if playing_sounds.size() >= MAX_SOUNDS_PLAYING: return
	var player := AudioStreamPlayer.new()
	sound.loop = false
	player.name = str(sound)
	player.stream = sound
	player.bus = options.get("bus", "Master")
	player.volume_db = options.get("volume", 0.0)
	player.pitch_scale = maxf(options.get("pitch", 1.0), 0.001)
	if options.get("autofree", true): playing_sounds.append(player)
	add_child(player)
	player.play()
	if options.get("return", false): return player


func menusound(pitch := 1.0, options := {}) -> void:
	options.merge({"pitch": pitch, "volume": -8}, true)
	play_sound(preload("res://sounds/gui.ogg"), options)


# clearing silent audio players
func _on_sound_clear_timer_timeout() -> void:
	for s in playing_sounds:
		if not is_instance_valid(s): continue
		var player := s as AudioStreamPlayer
		if !player.playing and !player.stream_paused:
			playing_sounds.erase(player)
			player.call_deferred("queue_free")
	for s in playing_sounds:
		if not is_instance_valid(s):
			playing_sounds.erase(s)


func kill_sounds() -> void:
	for s in playing_sounds:
		var p := s as AudioStreamPlayer
		if not p == current_song_player:
			p.stop()
