extends Node2D

@onready var woodsman: OverworldCharacter = $Woodsman
@onready var mobulate: ColorContainer = $"../CanvasModulateGroup/Mobulate"


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
	DAT.set_data(&"got_flower_rose", true)
	var tw := create_tween()
	SND.play_song("")
	tw.tween_property(mobulate, ^"color", Color(0.66, 0.31, 0.862), 2.0)
