extends Room

@onready var musicplayer := $Radio/RadioMusic
@export_range(-1, 10) var prank_call_force := -1
@onready var door_area: Area2D = $Door/DoorArea
@onready var radio := $Radio


func _ready() -> void:
	super._ready()

	if DAT.flower_progress(ResMan.get_character("greg").inventory) >= 8:
		for n in get_tree().get_nodes_in_group("empty_delete"): n.queue_free()
		door_area.destination = &"secret_garden_entrance"
		musicplayer.stop()
		radio.default_song = preload("res://music/mus_bells.ogg")
		radio.radio_song = null
		return
	# long grandma lol
	if Math.inrange(DAT.get_data("nr", 0), 0.665, 0.67) and not DAT.get_data("sscyr", false):
		DAT.set_data("sscyr", true)
		$Grandma/AnimatedSprite2D.scale.y = 4.875
		$Grandma.default_lines.clear()
		$Grandma.default_lines.append(&"grandma_fight_1")


func _on_phone_interacted() -> void:
	if DAT.get_data("pranked", false):
		SOL.dialogue("prank_call_enough")
		return
	var number: int = int(DAT.get_data("nr", 0.0) * 10.0 + 1)
	if prank_call_force > -1:
		number = prank_call_force
	var call_name := "prank_call_%s"
	if number == 10:
		if musicplayer.playing:
			musicplayer.stop()
	SOL.dialogue_box.dial_concat("prank_call_0", 1, [number])
	SOL.dialogue("prank_call_0")
	if call_name % number in SOL.dialogue_box.dialogues_dict.keys():
		SOL.dialogue(call_name % number)
	else:
		SOL.dialogue("prank_call_else")
	SOL.dialogue("prank_call_over")
	DAT.set_data("pranked", true)
