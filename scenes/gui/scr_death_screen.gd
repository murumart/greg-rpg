extends Control

const DEATH_PICTURE_PATH := "res://sprites/death/spr_%s.png"
const DEATH_REASONS := [
	{
		"picture": "default",
		"sound": "res://music/mus_defeat.ogg",
		"text": "[center]your resolve was overcome.[/center]"
	},
	{
		"picture": "car",
		"text": "[center]ride, ride, ride, until you find yourself again.[/center]"
	},
	{
		"picture": "bikecry",
		"text": "[center]invest in roads, politicians!"
	},
	{
		"picture": "mail_disappointment",
		"text": "[center]..."
	},
	{
		"picture": "snail_beam",
		"text": "[center]you are in for a world of 4000k!"
	},
	{
		"picture": "drinking",
		"text": "[center]drowning in sadness!"
	},
	{
		"picture": "moron",
		"text": ""
	},
	{
		"picture": "cats",
		"text": "[center]meow all you want, there is no one to save you."
	},
	{
		"picture": "solar",
		"text": "[center]don't fly too close."
	},
	{
		"picture": "nova",
		"text": "[center]almost worth dying for a sight like this.",
		"sound": ""
	},
	{
		"picture": "zerma",
		"text": "[center]why did it have to end this way... so young...",
	},
	{
		"picture": "vampire",
		"text": "[center]looooooooseeeeeeeer!",
	},
	{
		"picture": "president_gun",
		"text": "[center]gun",
		"sound": "res://sounds/spirit/dishpunch.ogg"
	},
	{
		"picture": "dish",
		"text": "[center]sleep with the dishes / for a 1000 years",
	},
	{
		"picture": "gdung",
		"text": "[center]it goes deep.",
	},
	{
		"picture": "mayordiea",
		"text": "[font=res://fonts/gregtiny.ttf][font_size=6][center]assignment terminated\nsubject: greg\nreason: failure to preserve mission-critical personnel",
	}
]

@export var test_death := DAT.DeathReasons.DEFAULT

@onready var text_box := $TextBox
@onready var picture := $Pictures
@onready var retry_button: Button = $HBoxContainer/RetryButton
@onready var quit_button: Button = $HBoxContainer/QuitButton

var leaving := false


func _ready() -> void:
	DAT.free_player("all")
	if DAT.seconds < 2:
		DAT.death_reason = test_death
	var death_reason: Dictionary = DEATH_REASONS[DAT.death_reason]
	DAT.appenda("deaths", DAT.death_reason)
	DAT.force_data("deaths", DAT.get_data("deaths", []))
	if death_reason.get("sound", "blblb"):
		SND.play_sound(load(death_reason.get("sound", "res://music/mus_defeat.ogg")), {"bus": "Music"})
	picture.texture = load(DEATH_PICTURE_PATH % death_reason.get("picture", "default"))
	text_box.text = death_reason.get("text", "[center]your resolve was overcome.[/center]")
	text_box.speak_text({"speed": 2})
	DAT.death_reason = DAT.DeathReasons.DEFAULT
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
