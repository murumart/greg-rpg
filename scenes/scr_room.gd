extends Node2D
class_name Room

# overworld room scenes

@export var music := ""
@export var music_fade_time := 1.0
@export var music_save_progress := true
@export var music_play_from_beginning := false
@export var music_start_volume := -80.0


func _init() -> void:
	# so i don't have to manually :dace:
	self.add_to_group("save_me")


func _ready() -> void:
	var sname := name.to_snake_case()
	DAT.set_data("current_room", sname)
	var visited_rooms: Array = DAT.get_data("visited_rooms", [])
	if not sname in visited_rooms:
		visited_rooms.append(sname)
	DAT.set_data("visited_rooms", visited_rooms)
	SOL.dialogue_choice = ""

	SND.play_song(music, music_fade_time,
		{
			"start_volume": music_start_volume,
			"play_from_beginning": music_play_from_beginning,
			"save_audio_position": music_save_progress
		}
	)
	spawn_cigarettes()


func _save_me() -> void:
	DAT.set_data("current_room", name.to_snake_case())


func spawn_cigarettes() -> void:
	var key := "cigarettes_in_" + name.to_snake_case()
	var positions := DAT.get_data(key, {}) as Dictionary
	for pos: Vector2 in positions:
		var cig := CigaretteOverworld.SCENE.instantiate()
		add_child(cig)
		cig.global_position = pos
		cig.rotation = positions[pos]["rotation"]
		cig.start_timer(positions[pos]["time"])
