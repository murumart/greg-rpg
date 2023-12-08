extends Control

# the main menu. surprise surprise

var pos := 0
var menusound := preload("res://sounds/gui.ogg")
var starting := false

@onready var buttons := [
	$VBoxContainer/NewGameButton, $VBoxContainer/LoadGameButton, $VBoxContainer/MailButton,$VBoxContainer/QuitButton
]


func _ready() -> void:
	#await load_all_effects()
	$LoadingScreen.hide()
	$VBoxContainer/NewGameButton.grab_focus()
	choose_music()
	if randf() >= 0.5 and DIR.gej(0, 0) > 0:
		$Label.text = "[center]" + str(get_funny_messages().pick_random())
		if $Label.text.ends_with("[/url]"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# mail message
	for b in buttons:
		b.focus_exited.connect(_on_button_focus_exited.bind(b))
	if randf() <= 0.01:
		$VBoxContainer/MailButton/MailPanel/RichTextLabel.text = HateMail.letter()
		$VBoxContainer/MailButton.visible = true
		$VBoxContainer/LoadGameButton.focus_neighbor_bottom = $VBoxContainer/MailButton.get_path()
		$VBoxContainer/MailButton.focus_neighbor_top = $VBoxContainer/LoadGameButton.get_path()
		$VBoxContainer/MailButton.focus_neighbor_bottom = $VBoxContainer/QuitButton.get_path()
		$VBoxContainer/QuitButton.focus_neighbor_top = $VBoxContainer/MailButton.get_path()
	DIR.incj(0, 1)


func _input(event: InputEvent) -> void:
	if starting: return
	if not event is InputEventKey: return
	var hf := (
		func buttons_have_focus() -> bool:
			for b in buttons:
				if b.has_focus(): return true
			return false
	)
	if not hf.call() and not SOL.save_menu_open:
		$VBoxContainer/NewGameButton.grab_focus.call_deferred()
	if event.is_action_pressed("ui_cancel"):
		$VBoxContainer/MailButton/MailPanel.hide()
		$VBoxContainer/NewGameButton.grab_focus.call_deferred()


func _on_new_game_button_pressed() -> void:
	DAT.start_game()
	# wow! chord
	SND.play_sound(menusound, {"bus": "ECHO"})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch": 1.33})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch": 1.96})
	SND.play_song("")
	starting = true
	get_viewport().gui_release_focus()


func _on_load_game_button_pressed() -> void:
	SOL.save_menu(true, {"restrict": 1}) # only allow loading


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))


func _on_button_focus_exited(_button: Button) -> void:
	if OPT.options_open: return 
	SND.play_sound(menusound)


# play only the first 2 menu themes on game start up
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
		SND.list.songs[SND.list.songs.keys().pick_random()]["title"],
		SND.current_song.get("title"),
		"",
		"thank you webcatz!",
		"thank you radio!",
		"newspaper boy...",
		"don't eat the soap." if randf() < 0.75 else "don't eat the soup" if randf() < 0.5 else "don't eat the saup" if randf() < 0.25 else "don't eat the soeuüp",
		"histories of mail and man",
		"greg",
		"[color=#8888ff][u][url=https://www.google.com/search?q=greg+merch]buy cool merch! ->[/url]"
	]


var read_messages := false
func _on_mail_button_pressed() -> void:
	$VBoxContainer/MailButton/MailPanel.visible = not $VBoxContainer/MailButton/MailPanel.visible
	$VBoxContainer/MailButton.text = " messages"
	$VBoxContainer/MailButton/Sprite2D.hide()
	if not read_messages:
		DIR.incj(120, 1)
	read_messages = true


# maybe it caches them somewhere so it will be less laggy than loading it during runtime
func load_all_effects() -> void:
	AudioServer.set_bus_mute(0, true)
	var path := "res://scenes/vfx/"
	var names := DIR.get_dir_contents(path)
	for file in names:
		var fpath := path + file + ".tscn"
		if ResourceLoader.exists(fpath):
			var scene := SOL.vfx(file.trim_prefix("scn_vfx_"), Vector2(), {"silent": true})
			#scene.hide()
			scene.modulate.a = 0.0
			#await get_tree().process_frame
			scene.queue_free()
	SND.kill_sounds()
	#await get_tree().process_frame
	AudioServer.set_bus_mute(0, false)
