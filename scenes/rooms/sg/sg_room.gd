extends Node

@export var collision_hide: CanvasItem
@export var song_pitch := 1.0


func _ready() -> void:
	# window resolution change is in camera node.
	collision_hide.hide()
	#await get_parent().ready # parent shiould be Room root node
	await get_tree().process_frame # waitinf for parent ready (room plays music)
	if is_instance_valid(SND.current_song_player):
		SND.current_song_player.pitch_scale = song_pitch
