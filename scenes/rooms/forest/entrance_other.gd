extends Node2D

@onready var woodsman: OverworldCharacter = $Woodsman
@onready var mobulate: ColorContainer = $"../CanvasModulateGroup/Mobulate"
@onready var forest_music: AudioStreamPlayer2D = $"../Areas/RoomGate2/AudioStreamPlayer2D"
@onready var greg: PlayerOverworld = $"../Greg"


func _ready() -> void:
	var inv := ResMan.get_character(&"greg").inventory
	woodsman.inspected.connect(func() -> void:
		if inv.count(&"rose_petals") >= 20 and inv.count(&"rose_thorns") >= 20 and not DAT.get_data(&"got_flower_rose", false):
			woodsman.default_lines = []
			_rose_cutscene()
			return

		var choices := [&"bye", &"woods", &"you", &"me"]
		if DAT.get_data(&"flowerboy_talked_woods", false):
			choices.append(&"air")
			choices.append(&"exit")
		if DAT.get_data(&"forest_max_depth", 0) > 0:
			choices.append(&"glass")
		if DAT.get_data(&"flowerboy_talked_you", false) and DAT.get_data(&"flowerboy_talked_me", false):
			choices.append(&"flower")
		SOL.dialogue_box.adjust("woods_guy_help", 0, &"choices", choices)
	)


func _rose_cutscene() -> void:
	DAT.capture_player("cutscene")
	var tw := create_tween()
	SND.play_song("")
	tw.tween_property(mobulate, ^"color", Color(0.66, 0.31, 0.862), 2.0)
	tw.tween_callback(func() -> void: greg.animate("walk_down", true))
	tw.parallel().tween_property(forest_music, ^"volume_db", -80, 1.0)
	tw.parallel().tween_property(greg, ^"global_position", woodsman.global_position + Vector2.DOWN * 12, 1.0)
	tw.tween_callback(func() -> void:
		greg.animate("walk_up")
		SND.play_song("extremophile", 0.5, {pitch_scale = 0.89})
	)
	tw.tween_interval(0.2)
	await tw.finished
	SOL.dialogue("woods_guy_has_materials")
	await SOL.dialogue_closed
	DAT.set_data(&"got_flower_rose", true)
	var inv := ResMan.get_character(&"greg").inventory
	for i in 20:
		inv.erase(&"rose_petals")
		inv.erase(&"rose_thorns")
	inv.append(&"flower_rose")
	SND.play_song("")
	await Math.timer(0.5)
	SOL.dialogue("woods_guy_after_2")
	await SOL.dialogue_closed
	await Math.timer(1.0)
	SOL.dialogue("woods_guy_after_3")
