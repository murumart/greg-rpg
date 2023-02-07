extends Node

# options menu
var IONS := {
	screen_shake_intensity = 1.0,
	text_speak_time = 0.75,
}
const CATEGORIES := {
	"graphics": ["screen_shake_intensity", "text_speak_time"]
}

# tools
var opt := ConfigFile.new()
const OPTION_PATH := "user://greg_rpg/options.ini"

# nodes
@onready var root := $Root
@onready var main_container := $Root/Panel/ScrollContainer/MainContainer
@onready var base_option := $Root/BaseOption


func _init() -> void:
	print("OPT init")
	if not DIR.file_exists(OPTION_PATH, true):
		opt.set_value("promo", "website", "https://murumart.neocities.org/")
		opt.save(OPTION_PATH)
	opt.load(OPTION_PATH)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	gen_option_nodes()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_KP_1:
				SOL.vfx("damage_number", get_viewport().get_mouse_position(), {text = randi()%667, size= randi()%2 + 1})


func gen_option_nodes() -> void:
	for i in CATEGORIES.keys():
		var opts := CATEGORIES[i] as Array
		var label := Label.new()
		main_container.add_child(label)
		label.text = i
		for j in opts:
			var option := base_option.duplicate()
			main_container.add_child(option)
			option.show()
			option.get_child(0).text = str(j).replace("_", " ")
			option.get_child(1).text = str(IONS.get(j))

