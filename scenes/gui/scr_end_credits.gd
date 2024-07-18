extends Node2D

@onready var credits_label: Label = %CreditsLabel
@onready var credits_scroll_container: ScrollContainer = $CreditsScrollContainer
@onready var credits_scroll: VScrollBar = credits_scroll_container.get_v_scroll_bar()

@onready var image_scroll_container: ScrollContainer = $ImageScrollContainer
@onready var image_container: VBoxContainer = %ImageContainer
@onready var image_scroll := image_scroll_container.get_v_scroll_bar()
@onready var return_label: Label = $ReturnLabel

var scroll_speed := 0.0


func _ready() -> void:
	credits_label.text = "\n".repeat(8)
	credits_label.text += FileAccess.open("res://credits.txt",
			FileAccess.READ).get_as_text(true)
	credits_label.text += "see credits in main menu for full attribution."
	_load_pictures()
	SND.play_song("credits")
	var duration := SND.current_song_player.stream.get_length()
	await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(credits_scroll, "value", credits_scroll.max_value
			- credits_scroll.size.y, duration)
	tw.parallel().tween_property(image_scroll, "value", image_scroll.max_value
			- image_scroll.size.y, duration)
	tw.finished.connect(func():
		tw = create_tween()
		tw.tween_property(return_label, "self_modulate:a", 1.0, 2.0).set_delay(2.0)
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		LTS.level_transition("res://scenes/gui/scn_main_menu.tscn")


func _load_pictures() -> void:
	var screenshots := DIR.get_screenshots()
	#print(screenshot_folder)
	for i in 7:
		if i >= screenshots.size():
			break
		var filename: String = screenshots[i]
		var display := TextureRect.new()
		display.texture = ImageTexture.create_from_image(Image.load_from_file(filename))
		display.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		display.stretch_mode = TextureRect.STRETCH_SCALE
		image_container.add_child(display)

