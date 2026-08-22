extends Control

# the main menu. surprise surprise

var pos := 0
var menusound := preload("res://sounds/gui.ogg")
var starting := false

@onready var version_text: Label = $VersionText
@onready var funny_text: RichTextLabel = $FunnyText
@onready var loading_screen: ColorRect = $LoadingScreen

@export var new_game_button: Button
@export var load_game_button: Button
@export var mail_button: Button
@export var credits_button: Button
@export var quit_button: Button
@onready var buttons: Array[Button] = [
	new_game_button,
	load_game_button,
	mail_button,
	credits_button,
	quit_button,
]

@export var credits_text_panel: Panel
@export var credits_autoscroll: AutoscrollComponent
@export var credits_label: RichTextLabel

@export var mail_panel: Panel
@export var mail_label: RichTextLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	load_game_button.pressed.connect(_on_load_game_button_pressed)
	mail_button.pressed.connect(_on_mail_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	DAT.A = {}
	ResMan.load_resources()
	SOL.load_all_effects()
	loading_screen.call_deferred("hide")
	new_game_button.grab_focus()
	choose_music()
	version_text.text += " " + DAT.version_str()
	funny_text.text = "[center]" + str(get_funny_messages().pick_random())
	if funny_text.text.ends_with("[/url]"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# mail message
	for b in buttons:
		b.focus_exited.connect(_on_button_focus_exited.bind(b))
	if randf() <= 0.01:
		mail_label.text = HateMail.letter()
		mail_button.visible = true
	button_focuses()
	_load_credits()
	DAT.player_capturers.clear()
	if randf() <= 0.008:
		for x in buttons:
			var mov := ScreenEdgeBounceComponent.new()
			mov.target = x
			mov.bounce_rect.size.x -= 90
			x.add_child(mov)
	DIR.incj(0, 1)


func _input(event: InputEvent) -> void:
	if starting:
		return
	if not event is InputEventKey:
		return
	var hf := (buttons.any(func(a: Button): return a.has_focus()))
	if (not hf
			and not SOL.save_menu_open
			and not SOL.dialogue_open
			#and not $VBoxContainer/CreditsButton/TextPanel.visible
			and DAT.player_capturers.is_empty()):
		if event.is_action_pressed("cancel"):
			mail_panel.hide()
			credits_text_panel.hide()
			new_game_button.grab_focus.call_deferred()
		#elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		#	new_game_button.grab_focus.call_deferred()


func _on_new_game_button_pressed() -> void:
	DAT.init_data()
	DAT.set_data("nr", randf())
	LTS.level_transition("res://scenes/cutscene/scn_intro.tscn", {"fade_time": 2.0})
	# wow! chord
	SND.play_sound(menusound, {"bus": "ECHO"})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch_scale": 1.33})
	SND.play_sound(menusound, {"bus": "ECHO", "pitch_scale": 1.96})
	SND.play_song("")
	starting = true
	get_viewport().gui_release_focus()


func _on_load_game_button_pressed() -> void:
	# only allow loading, enable deleting saves
	SOL.save_menu(true, {"restrict": 1, "erasure_enabled": true})


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))


func _on_button_focus_exited(_button: Button) -> void:
	if OPT.options_open: return
	SND.play_sound(menusound)
	credits_text_panel.hide()


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
		"",
		"thank you lamb!",
		"thank you radio!",
		"thank you alan!",
		"newspaper boy...",
		"don't eat the soap." if randf() < 0.75 else "don't eat the soup" if randf() < 0.5 else "don't eat the saup" if randf() < 0.25 else "don't eat the soeuüp",
		"histories of mail and man",
		"greg",
	]


var read_messages := false
func _on_mail_button_pressed() -> void:
	get_viewport().gui_release_focus()
	mail_panel.visible = not mail_panel.visible
	mail_button.text = " messages"
	mail_button.get_child(0).hide()
	if not read_messages:
		DIR.incj(120, 1)
	read_messages = true


func button_focuses() -> void:
	var sz := buttons.size()
	var y := 0
	for x in sz:
		y = wrapi(x + 1, 0, sz)
		var current := buttons[x]
		if not current.visible:
			continue
		var next := buttons[y]
		while not next.visible:
			y = wrapi(y + 1, 0, sz)
			next = buttons[y]
		current.focus_neighbor_bottom = next.get_path()
		next.focus_neighbor_top = current.get_path()


func _on_credits_button_pressed() -> void:
	get_window().gui_release_focus()
	credits_text_panel.show()
	credits_autoscroll.reset.call_deferred()


func _load_credits() -> void:
	var text := FileAccess.open("res://credits.txt", FileAccess.READ).get_as_text()
	text += "\n\n"
	text += FileAccess.open("res://LICENSE.txt", FileAccess.READ).get_as_text()
	text += "\n\n"
	text += FileAccess.open("res://shaders/CREDITS.txt", FileAccess.READ).get_as_text()
	text += "\n\n"
	text += Engine.get_license_text()
	text += "\n"
	text += "Portions of this software are copyright © <year> The FreeType Project (www.freetype.org). All rights reserved.\n"
	text += """

	Copyright (c) 2002-2020 Lee Salzman

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\n"""
	text += """

	Copyright The Mbed TLS Contributors

	Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.\n
"""
	text += var_to_str(Engine.get_license_info())
	text += "\n"
	text += var_to_str(Engine.get_copyright_info())

	credits_label.text = text
