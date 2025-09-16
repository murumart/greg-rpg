extends Node2D

@onready var flower_circle: Node2D = $FlowerCircle


func _ready() -> void:
	var inv := ResMan.get_character(&"greg").inventory
	for i in DAT.FLOWERS.size():
		var nam: StringName = DAT.FLOWERS[i]
		var nod: Sprite2D = flower_circle.get_child(i)
		if not nam in inv:
			nod.modulate = Color(0, 0, 0, 0.5)


var _d := 0.0
func _process(delta: float) -> void:
	_d += delta
	if _d >= 8.0 or Input.is_action_just_pressed(&"cancel"):
		set_process(false)
		LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
		LTS.level_transition(LTS.ROOM_SCENE_PATH %
				DAT.get_data("current_room", "test_room"))
