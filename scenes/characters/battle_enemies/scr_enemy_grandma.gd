extends BattleEnemy


func _ready() -> void:
	super._ready()


func act() -> void:
	var greg : BattleActor = reference_to_opposing_array[0]
	if greg.character.health_perc() > 0.5:
		ai_action()
	else:
		DAT.set_data("fought_grandma", true)
		LTS.gate_id = LTS.GATE_EXIT_BATTLE
		LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))
