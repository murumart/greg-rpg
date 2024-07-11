extends Node2D

@export var battle_infos: Array[BattleInfo]
@onready var screener: Sprite2D = $Screener


func _on_area_2d_body_entered(_body: PlayerOverworld) -> void:
	var gdung_floor: int = DAT.get_data("gdung_floor", 0)
	LTS.gate_id = &"gdung_advance"
	remove_child(screener)
	SOL.add_ui_child(screener, 121)
	screener.show()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(screener, "material:shader_parameter/modulate_a", 1.0, 1.0).from(0.0)
	tw.parallel().tween_property(screener, "scale", Vector2(20, 10), 4.0)
	LTS.enter_battle(battle_infos[gdung_floor])
	DAT.set_data("gdung_gen_next_floor", true)
