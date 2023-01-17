extends Room

@onready var sprite := $SprIcon
var speed := 60.0


func _ready() -> void:
	var dict := {
	}
	
	dict["ass"] = 0.213124214124
	
	var button_functions := [save_pressed, load_pressed, shake_pressed, trash_pressed, speak_pressed, dialogue_speak_pressed, play_music_pressed, fade_screen_pressed, leave_pressed]
	for i in button_functions.size():
		var callable := button_functions[i] as Callable
		var button := $Buttons.get_child(i) as Button
		button.pressed.connect(callable)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$RichTextLabel.skip_to_end()
	if event.keycode == KEY_END and event.pressed:
		DAT.print_data()


func _physics_process(delta: float) -> void:
	sprite.global_position.x += int(Input.get_axis("ui_left", "ui_right") * delta * speed)
	sprite.global_position.y += int(Input.get_axis("ui_up", "ui_down") * delta * speed)


func save_pressed():
	DAT.save_data()


func load_pressed():
	DAT.load_data()


func shake_pressed():
	$Greg/Camera.add_trauma(0.6)


func trash_pressed():
	DAT.set_data(str(randf_range(-1, 1)), (str(randf_range(-100, 100))))
	DAT.print_data()


func speak_pressed():
	$RichTextLabel.visible_ratio = 0.0
	$RichTextLabel.text = str(randi())
	$RichTextLabel.speak_text({"speaking_speed": randf_range(0.5, 2.0)})


func dialogue_speak_pressed():
	SOL.dialogue("test")


func play_music_pressed():
	SND.play_song(SND.list.songs.keys().pick_random())


func fade_screen_pressed():
	SOL.fade_screen(Color(0, 0, 0, 0), Color(0, 0, 0, 1))
	await SOL.fade_finished
	SOL.fade_screen(Color(0, 0, 0, 1), Color(1, 1, 1221, 0))


func leave_pressed():
	LTS.level_transition("res://scenes/characters/overworld/scn_greg_overworld.tscn")
