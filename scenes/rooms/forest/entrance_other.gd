extends Node2D

const FLOWER_PIECE_COUNT := 10

@onready var woodsman: OverworldCharacter = $Woodsman
@onready var mobulate: ColorContainer = $"../CanvasModulateGroup/Mobulate"
@onready var forest_music: AudioStreamPlayer2D = $"../Areas/RoomGate2/AudioStreamPlayer2D"
@onready var greg: PlayerOverworld = $"../Greg"


func _ready() -> void:
	if DAT.get_data(&"got_flower_rose", false):
		queue_free()
	var inv := ResMan.get_character(&"greg").inventory
	woodsman.inspected.connect(func() -> void:
		if DAT.get_data(&"got_flower_rose", false):
			SOL.dialogue_d(DialogueBuilder.new().add_line(DialogueLine.mk("...")).get_dial())
			return
		if inv.count(&"rose_petals") >= FLOWER_PIECE_COUNT and inv.count(&"rose_thorns") >= FLOWER_PIECE_COUNT and not DAT.get_data(&"got_flower_rose", false):
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
	DAT.appenda_uq("tarikas_topics", "flowerboy")
	DAT.capture_player("cutscene")
	var tw := create_tween()
	SND.play_song("")
	tw.tween_property(mobulate, ^"color", Color(0.66, 0.31, 0.862), 2.0)
	tw.tween_callback(func() -> void: greg.animate("walk_down", true))
	tw.parallel().tween_property(forest_music, ^"volume_db", -80, 1.0)
	tw.parallel().tween_property(greg, ^"global_position", woodsman.global_position + Vector2.DOWN * 12, 1.0)
	tw.tween_callback(func() -> void:
		greg.animate("walk_up")
		SND.play_song("extremophile", 0.89, {pitch_scale = 0.89, play_from_beginning = true})
	)
	tw.tween_interval(0.2)
	await tw.finished
	SOL.dialogue("woods_guy_has_materials")
	await SOL.dialogue_closed
	DAT.set_data(&"got_flower_rose", true)
	var inv := ResMan.get_character(&"greg").inventory
	for i in FLOWER_PIECE_COUNT:
		inv.erase(&"rose_petals")
		inv.erase(&"rose_thorns")
	inv.append(&"flower_rose")
	await Math.timer(1.0)
	SOL.dialogue("woods_guy_after_2")
	await SOL.dialogue_closed
	tw = create_tween()
	DAT.free_player("cutscene")
	tw.tween_property(mobulate, ^"color", Color.WHITE, 8.0)
