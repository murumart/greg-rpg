extends Node2D


func _on_area_2d_body_entered(body: PlayerOverworld) -> void:
	LTS.level_transition("res://scenes/rooms/scn_room_grandma_after_fight_staredown.tscn")
