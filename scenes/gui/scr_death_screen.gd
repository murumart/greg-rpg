extends Control

const DEATH_PICTURE_PATH := "res://sprites/death/spr_%s.png"
const DEATH_REASONS := {
	"default": {
		"picture": "default",
		"sound": "res://music/mus_defeat.ogg",
		"text": "[center]your resolve was overcome.[/center]"
	},
	"car": {
		"picture": "car",
		"text": "[center]ride, ride, ride, until you find yourself again.[/center]"
	},
	"bikecry": {
		"picture": "bikecry",
		"text": "[center]invest in roads, politicians!"
	},
	"mail_disappointment": {
		"picture": "mail_disappointment",
		"text": "[center]..."
	},
	"snail_beam": {
		"picture": "snail_beam",
		"text": "[center]you are in for a world of 4000k!"
	}
}

@onready var text_box := $TextBox
@onready var picture := $Pictures

@export var test_death := ""


func _ready() -> void:
	if test_death:
		DAT.death_reason = test_death
	SND.play_sound(load(DEATH_REASONS.get(DAT.death_reason, {}).get("sound", "res://music/mus_defeat.ogg")), {"bus": "Music"})
	picture.texture = load(DEATH_PICTURE_PATH % DEATH_REASONS.get(DAT.death_reason, {}).get("picture"))
	text_box.text = DEATH_REASONS.get(DAT.death_reason, {}).get("text", "")
	text_box.speak_text({"speed": 2})
	DAT.death_reason = "default"
	$HBoxContainer/RetryButton.call_deferred("grab_focus")


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$HBoxContainer/RetryButton.grab_focus()


func _on_retry_button_pressed() -> void:
	SOL.save_menu(true, {"restrict": 1})


func _on_quit_button_pressed() -> void:
	LTS.level_transition("res://scenes/gui/scn_main_menu.tscn")
