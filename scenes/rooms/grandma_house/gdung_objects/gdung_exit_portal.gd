extends Node2D

@export var battle_infos: Array[BattleInfo]


func _on_area_2d_body_entered(_body: PlayerOverworld) -> void:
	var floor: int = DAT.get_data("gdung_floor", 0)
	LTS.gate_id = &"gdung_advance"
	#LTS.level_transition("res://scenes/rooms/scn_room_dungeon.tscn")
	LTS.enter_battle(battle_infos[floor])
	DAT.set_data("gdung_gen_next_floor", true)
