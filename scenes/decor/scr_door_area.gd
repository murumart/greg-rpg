extends Area2D

@export var destination := &""
@export var gate_id := &""

@export var spawn_point : Node2D
@export var player : PlayerOverworld

@export var fail_dialogue := "door_unanswer"


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if LTS.gate_id == gate_id:
		if not player or not spawn_point: return
		player.global_position = spawn_point.global_position


func interacted() -> void:
	if DIR.room_exists(destination):
		LTS.gate_id = gate_id
		LTS.level_transition(DIR.room_scene_path(destination))
	else:
		DAT.capture_player("knocking_on_door")
		var knock_sound : AudioStreamPlayer = SND.play_sound(preload("res://sounds/snd_door_knock.ogg"), {"autofree": false, "return": true})
		await knock_sound.finished
		DAT.free_player("knocking_on_door")
		SOL.dialogue(fail_dialogue)
		knock_sound.queue_free()
