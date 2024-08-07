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
	},
	"lakeside": {
		"picture": "drinking",
		"text": "[center]drowning in sadness!"
	},
	"moron": {
		"picture": "moron",
		"text": ""
	},
	"cats": {
		"picture": "cats",
		"text": "[center]meow all you want, there is no one to save you."
	},
	"solar": {
		"picture": "solar",
		"text": "[center]don't fly too close."
	},
	"nova": {
		"picture": "nova",
		"text": "[center]almost worth dying for a sight like this.",
		"sound": ""
	},
	"sus": {
		"picture": "zerma",
		"text": "[center]why did it have to end this way... so young...",
	},
	"vampire": {
		"picture": "vampire",
		"text": "[center]looooooooseeeeeeeer!",
	},
	"president_gun": {
		"picture": "president_gun",
		"text": "[center]gun",
		"sound": "res://sounds/spirit/dishpunch.ogg"
	},
	"dish": {
		"picture": "dish",
		"text": "[center]sleep with the dishes / for a 1000 years",
	},
	"gdung": {
		"picture": "gdung",
		"text": "[center]it goes deep.",
	}
}
@export var test_death := ""

@onready var text_box := $TextBox
@onready var picture := $Pictures
@onready var retry_button: Button = $HBoxContainer/RetryButton
@onready var quit_button: Button = $HBoxContainer/QuitButton

var leaving := false


func _ready() -> void:
	DAT.free_player("all")
	if test_death.length() > 0 and DAT.seconds < 2:
		DAT.death_reason = test_death
	var death_reason: Dictionary = DEATH_REASONS.get(DAT.death_reason, {})
	if death_reason.get("sound", "blblb"):
		SND.play_sound(load(death_reason.get("sound", "res://music/mus_defeat.ogg")), {"bus": "Music"})
	picture.texture = load(DEATH_PICTURE_PATH % death_reason.get("picture", "default"))
	text_box.text = death_reason.get("text", "[center]your resolve was overcome.[/center]")
	text_box.speak_text({"speed": 2})
	{true:func():{0:func():DIR.sej(125,1)}.get(DIR.gej(2,0),func(
	):pass).call(),false:func():pass}[DAT.death_reason=="sus"].call()
	DAT.death_reason = "default"
	retry_button.call_deferred("grab_focus")
	DIR.incj(2, 1)
	if Math.inrange(DAT.get_data("nr"), 0.85, 0.86):
		retry_button.text = "restry"
		quit_button.text = "quite"
	if LTS.gate_id == &"fake_game_over":
		retry_button.disabled = true
		quit_button.disabled = true
		create_tween().tween_interval(3.0).finished.connect(func():
			LTS.gate_id = LTS.GATE_LOADING
			LTS.change_scene_to(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))
		)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		retry_button.grab_focus()


func _on_retry_button_pressed() -> void:
	SOL.save_menu(true, {"restrict": 1}) # only allow loading


func _on_quit_button_pressed() -> void:
	if leaving:
		return
	LTS.level_transition("res://scenes/gui/scn_main_menu.tscn")
	leaving = true
