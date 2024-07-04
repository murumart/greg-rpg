extends Node2D


func _on_area_2d_body_entered(body: PlayerOverworld) -> void:
	DAT.incri("gdung_floor", 1)
	LTS.gate_id = &"gdung_advance"
	LTS.level_transition("res://scenes/rooms/scn_room_dungeon.tscn")
