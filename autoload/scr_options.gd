extends Node

# options menu
var IONS := {
	"screen_shake_intensity": {
		"value": 1.0,
		"range": [0.0, 2.0],
		"default_value": 1.0
	},
	"text_speak_time": {
		"value": 0.75,
		"range": [0.25, 2.0],
		"default_value": 0.75
	},
	"master_volume": {
		"value": 0.0,
		"range": [-60.0, 0.0],
		"default_value": 0.0,
		"step": 1.0,
	},
	"music_volume": {
		"value": -2.0,
		"range": [-80.0, 0.0],
		"default_value": -2.0,
		"step": 1.0,
	},
	"reset": {}
}
const CATEGORIES := {
	"sound": ["master_volume", "music_volume"],
	"graphics": ["screen_shake_intensity", "text_speak_time"],
	"": ["reset"]
}

# tools
var opt := ConfigFile.new()
const OPTION_PATH := "user://greg_rpg/options.ini"
@onready var menu_sound := preload("res://sounds/snd_gui.ogg")

# nodes
@onready var root := $Root
@onready var main_container := $Root/Panel/ScrollContainer/MainContainer
@onready var base_option := $Root/BaseOption

# selection
var cur_opt := 0
var options_length := 0


func _init() -> void:
	if not DIR.file_exists(OPTION_PATH, true):
		opt.set_value("promo", "website", "https://murumart.neocities.org/")
		opt.save(OPTION_PATH)
	opt.load(OPTION_PATH)


func _ready() -> void:
	gen_option_nodes()
	remove_child(root)
	SOL.add_ui_child(root, 128, false)
	root.hide()
	load_options()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_KP_1:
				SOL.vfx("damage_number", get_viewport().get_mouse_position() - Vector2(SOL.SCREEN_SIZE / 2), {text = "j", size= randi()%3 + 1})
			KEY_KP_0:
				DAT.print_data()
			KEY_KP_2:
				SOL.dialogue("cashier_mean_welcome")
		if event.is_action_pressed("escape"):
			if not root.visible:
				root.show()
				get_tree().paused = true
				cur_opt = 0
				select(cur_opt)
			else:
				save_options()
				root.hide()
				get_tree().paused = false
		if not root.visible: return
		var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var last_opt := cur_opt
		cur_opt = wrapi(cur_opt + int(move.y), 0, options_length)
		if cur_opt != last_opt:
			SND.play_sound(menu_sound)
		select(cur_opt)
		modify(move.x)


func save_options() -> void:
	for c in IONS.keys():
		var value = get_opt(c)
		opt.set_value(c, "value", value)
	opt.save(OPTION_PATH)


func load_options() -> void:
	for o in IONS.keys():
		var value : float = opt.get_value(o, "value", get_opt_default(o))
		set_opt(o, value)
	for y in options_length:
		cur_opt = y
		modify(0, false, true)


func select(opti: int) -> void:
	var opt_contain := get_option_nodes()
	for c in opt_contain:
		c.modulate = Color.WHITE
	opt_contain[opti].modulate = Color.CYAN


func modify(a: float, reset := false, ifset := false) -> void:
	var amt := signf(a)
	var opt_contain := get_option_nodes()
	var container := opt_contain[cur_opt]
	var type : String = container.get_meta("type", "")
	var prev_opt : Variant = get_opt(type)
	if not ifset:
		set_opt(type, clamp(get_opt(type) + amt * get_opt_step(type), get_opt_min(type), get_opt_max(type)))
	if reset:
		set_opt(type, get_opt_default(type))
		prev_opt = get_opt(type)
	update(container)
	# here we go
	AudioServer.set_bus_volume_db(0, get_opt("master_volume"))
	AudioServer.set_bus_volume_db(1, get_opt("music_volume"))
	if prev_opt == get_opt(type): return
	match type:
		"reset":
			reset_options()
			SND.play_sound(preload("res://sounds/snd_hurt.ogg"), {volume = 4.0})
		"master_volume":
			SND.play_sound(menu_sound, {pitch = 1.76})
		"music_volume":
			SND.play_sound(menu_sound, {bus = "Music", pitch = 0.89})
		"screen_shake_intensity":
			SOL.shake(1.0)


func update(container: Container) -> void:
	container.get_child(0).text = str(container.get_meta("type")).replace("_", " ")
	container.get_child(1).text = str(snapped(get_opt(container.get_meta("type")), 0.01))


func gen_option_nodes() -> void:
	options_length = 0
	for i in CATEGORIES.keys():
		var opts := CATEGORIES[i] as Array
		var label := Label.new()
		main_container.add_child(label)
		label.text = str("  ", i)
		for j in opts:
			var option := base_option.duplicate()
			main_container.add_child(option)
			option.show()
			option.set_meta("type", str(j))
			update(option)
			options_length += 1


func get_option_nodes() -> Array[Node]:
	var opt_contain := main_container.get_children()
	for o in opt_contain:
		if not o is Container:
			opt_contain.erase(o)
	return opt_contain


func get_opt(key: String) -> Variant:
	return IONS.get(key, {}).get("value", 0)


func get_opt_min(key: String) -> float:
	return IONS.get(key, {}).get("range", [0.0, 1.0])[0]


func get_opt_max(key: String) -> float:
	return IONS.get(key, {}).get("range", [0.0, 1.0])[1]


func get_opt_default(key: String) -> float:
	return IONS.get(key, {}).get("default_value", 0.0)


func get_opt_step(key: String) -> float:
	return IONS.get(key, {}).get("step", 0.1)


func set_opt(key: String, to: Variant) -> void:
	IONS[key]["value"] = to


func reset_options() -> void:
	for o in options_length:
		cur_opt = o
		modify(-1, true)

