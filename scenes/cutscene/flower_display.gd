extends Node2D

@onready var flower_circle: Node2D = $FlowerCircle
@onready var audio: AudioStreamSynchronized = $AudioStreamPlayer.stream
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

const ORDER := [7, 1, 5, 6, 3, 4, 0, 2]
"""
	&"flower0", 7
	&"flower1", 1
	&"flower2", 5
	&"flower3", 6
	&"flower4", 3
	&"flower5", 4
	&"flower6", 0
	&"flower7", 2
"""


var found := 0


func _ready() -> void:
	SND.play_song("")
	create_tween().tween_property(player, ^"volume_db", 0, 0.5).from(-60)
	for i in 8:
		audio.set_sync_stream_volume(i, linear_to_db(0.0))
	var inv := ResMan.get_character(&"greg").inventory
	for i in DAT.FLOWERS.size():
		var nam: StringName = DAT.FLOWERS[i]
		if not nam in inv:
			_flower(i).modulate = Color(Color.BLACK, 0.5)
			continue
		audio.set_sync_stream_volume(ORDER[i], linear_to_db(1.0))
		found += 1
	$AudioStreamPlayer.play()


var _d := 0.0
func _process(delta: float) -> void:
	_d += delta
	if _d >= 18.0 or Input.is_action_just_pressed(&"cancel"):
		set_process(false)
		LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
		LTS.level_transition(LTS.ROOM_SCENE_PATH %
				DAT.get_data("current_room", "test_room"))
		create_tween().tween_property(player, ^"volume_linear", 0.0, 0.2)
	flower_circle.rotation = sin(_d * 0.5 * (1 + found * 0.2)) * found * 0.125
	for i in 8:
		_flower(i).global_rotation = 0
		_flower(i).position.y += sin(_d * 2.0 + i * 0.1) * delta * found * 1.5


func _flower(i: int) -> Sprite2D:
	var f := flower_circle.get_child(i) as Sprite2D
	assert(f)
	return f
