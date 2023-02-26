extends Control

var pos := 0
var menusound := preload("res://sounds/snd_gui.ogg")
var starting := false


func _ready() -> void:
	$VBoxContainer/NewGameButton.grab_focus()
	choose_music()
	if randf() >= 0.5:
		$Label.text = "[center]" + str(get_funny_messages().pick_random())
		if $Label.text.ends_with("[/url]"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if starting: return
	if not event is InputEventKey: return
	var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var oldpos = pos
	pos += int(move.y)
	if pos != oldpos:
		SND.play_sound(menusound)
	if event.is_action_pressed("ui_cancel"):
		$VBoxContainer/NewGameButton.grab_focus()


func _on_new_game_button_pressed() -> void:
	DAT.start_game()
	SND.play_sound(menusound, {"bus": "ECHO"})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch": 1.33})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch": 1.96})
	SND.play_song("")
	starting = true
	get_viewport().gui_release_focus()


func _on_load_game_button_pressed() -> void:
	SOL.save_menu(true, {"restrict": 1})


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))


func choose_music() -> void:
	if DAT.seconds < 10:
		SND.play_song("menu_%s" % (randi() % 2 + 1))
	elif randf() <= 0.5:
		SND.play_song("menu_%s" % (randi() % 7 + 1))
	else:
		SND.play_song("menu_%s" % (randi() % 2 + 5))


func get_funny_messages() -> Array:
	return [
		"those who forget history...",
		"the willless worm",
		"the soulless snail",
		"new!",
		"in the flesh",
		SND.list.songs.get(SND.list.songs.keys().pick_random(), {}).get("title"),
		SND.current_song.get("title"),
		"",
		"thank you webcat!",
		"thank you radio!",
		"newspaper boy...",
		"don't eat the soap.",
		"histories of mail and man",
		"greg",
		"[color=#8888ff][u][url=https://www.google.com/search?q=greg+merch]buy cool merch! ->[/url]"
	]

