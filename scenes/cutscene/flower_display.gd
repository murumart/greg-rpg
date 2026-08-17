extends Node2D

const FlowerCircle = preload("res://scenes/cutscene/flower_circle.gd")

@onready var flower_circle: FlowerCircle = $FlowerCircle
@onready var audio: AudioStreamSynchronized = $AudioStreamPlayer.stream
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

const ORDER := [6, 1, 5, 3, 4, 0, 2]

var found := 0


func _ready() -> void:
	SND.play_song("")
	create_tween().tween_property(player, ^"volume_db", 0, 0.5).from(-60)
	for i in 7:
		audio.set_sync_stream_volume(i, linear_to_db(0.0))
	var inv := ResMan.get_character(&"greg").inventory
	for i in DAT.FLOWERS.size():
		var nam: StringName = DAT.FLOWERS[i]
		if not nam in inv:
			flower_circle.flower(i).modulate = Color(Color.BLACK, 0.5)
			continue
		audio.set_sync_stream_volume(ORDER[i], linear_to_db(1.0))
		found += 1
	flower_circle.found = found
	$AudioStreamPlayer.play()


var _d := 0.0
func _process(delta: float) -> void:
	_d += delta
	if _d >= 18.0 or Input.is_action_just_pressed(&"cancel"):
		set_process(false)
		LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
		LTS.level_transition(LTS.ROOM_SCENE_PATH %
				DAT.get_data("current_room", "waiting_room"))
		create_tween().tween_property(player, ^"volume_linear", 0.0, 0.2)
