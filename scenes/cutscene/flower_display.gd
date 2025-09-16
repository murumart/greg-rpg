extends Node2D

@onready var flower_circle: Node2D = $FlowerCircle
@onready var audio: AudioStreamSynchronized = $AudioStreamPlayer.stream
@onready var player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	SND.play_song("")
	create_tween().tween_property(player, ^"volume_db", 0, 0.5).from(-60)
	var inv := ResMan.get_character(&"greg").inventory
	var found := 0
	for i in DAT.FLOWERS.size():
		var nam: StringName = DAT.FLOWERS[i]
		var nod: Sprite2D = flower_circle.get_child(i)
		if not nam in inv:
			nod.modulate = Color(0, 0, 0, 0.5)
			continue
		found += 1
	if found > 2:
		audio.set_sync_stream_volume(1, 0.0)
	if found > 4:
		audio.set_sync_stream_volume(2, 0.0)
	if found == 8:
		audio.set_sync_stream_volume(0, 0.0)


var _d := 0.0
func _process(delta: float) -> void:
	_d += delta
	if _d >= 12.0 or Input.is_action_just_pressed(&"cancel"):
		set_process(false)
		LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
		LTS.level_transition(LTS.ROOM_SCENE_PATH %
				DAT.get_data("current_room", "test_room"))
		create_tween().tween_property(player, ^"volume_db", -60, 0.1)
