extends Node

# options menu
signal battle_text_opacity_changed

# all options are stored inside this dict
var IONS := {
	"screen_shake_intensity": {
		"value": 1.0, # used for storing the value
		"range": [0.0, 2.0], # min value and max value
		"default_value": 1.0 # what it is when reset
	},
	"text_speak_time": {
		"value": 0.75,
		"range": [0.25, 1.0],
		"default_value": 0.75
	},
	"main_volume": {
		"value": 0.0,
		"range": [-60.0, 0.0],
		"default_value": 0.0,
		"step": 1.0,# by what increment the value can go up or down
	},
	"music_volume": {
		"value": -2.0,
		"range": [-80.0, 0.0],
		"default_value": -2.0,
		"step": 1.0,
	},
	"list_button_focus_deferred": {
		"value": 0.0,
		"range": [0.0, 1.0],
		"default_value": 0.0,
		"step": 1.0
	},
	"log_data_changes": {
		"value": 0.0,
		"range": [0.0, 1.0],
		"default_value": 0.0,
		"step": 1.0
	},
	"max_fps": {
		"value": 60.0,
		"range": [5.0, 60.0],
		"default_value": 60.0,
		"step": 1.0,
	},
	"battle_text_opacity": {
		"value": 0.5,
		"range": [0.0, 1.0],
		"default_value": 0.5,
		"step": 0.1,
	},
	"less_fancy_graphics": {
		"value": 1.0,
		"range": [0.0, 1.0],
		"default_value": 0.0,
		"step": 1.0,
	},
	"view_keybinds": {
		"value": 0.0,
		"default_value": 0.0,
		"range": [0.0, 1.0],
		"step": 1.0,
	},
	"reset": {}
}
# sorting the options
const CATEGORIES := {
	"gameplay": ["view_keybinds"],
	"sound": ["main_volume", "music_volume"],
	"graphics": [
		"screen_shake_intensity", "text_speak_time",
		"max_fps", "battle_text_opacity", "less_fancy_graphics"
	],
	"debug": ["log_data_changes","list_button_focus_deferred"],
	"": ["reset"]
}

# are we open
var options_open := false

# tools
var opt := ConfigFile.new()
const OPTION_PATH := "user://greg_rpg/options.ini"
var top_text := 0

# nodes
@onready var root := $Root # confusing name but not the same as get_tree().root
@onready var main_container := $Root/Panel/ScrollContainer/MainContainer
@onready var base_option := $Root/BaseOption
@onready var top_text_label := $Root/Panel/TopTextLabel
@onready var keybinds := $Keybinds

# selection
var cur_opt := 0
var options_length := 0


func _init() -> void:
	# if we don't have an options file yet, create it
	if not DIR.file_exists(OPTION_PATH, true):
		opt.set_value("promo", "website", "https://murumart.neocities.org/") # :3
		opt.save(OPTION_PATH)
	opt.load(OPTION_PATH)


func _ready() -> void:
	gen_option_nodes()
	remove_child(root)
	SOL.add_ui_child(root, 128, false) # options gotta be on top
	remove_child(keybinds)
	SOL.add_ui_child(keybinds, 128, false) # options gotta be on top
	root.hide()
	load_options()


func _input(event: InputEvent) -> void:
	# DEBUG
	# remember to remove this when releasing the game
	if not DIR.standalone() and event is InputEventKey:
		match event.keycode:
			KEY_KP_0:
				DAT.copy_data()
				SOL.vfx_damage_number(
					Vector2.ZERO, "copied data", Color.WHITE, 2)
			KEY_KP_1:
				DAT.set_copied_data()
				SOL.vfx_damage_number(
					Vector2.ZERO, "replaced data", Color.WHITE, 2)
			KEY_KP_2:
				print(get_viewport().gui_get_focus_owner())
			KEY_KP_3, KEY_3:
				if not event.is_pressed():
					return
				if not get_viewport().get_camera_2d():
					var cam := preload(
						"res://scenes/tech/scn_camera.tscn"
						).instantiate()
					add_child(cam)
				if get_viewport().get_camera_2d() and\
				 "free_cam" in get_viewport().get_camera_2d():
					get_viewport().get_camera_2d().free_cam\
					 = !get_viewport().get_camera_2d().free_cam
			KEY_KP_4:
				get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint
				print("collisions ", "showing" if
				get_tree().debug_collisions_hint else "hidden")
			KEY_KP_7, KEY_7:
				if not root.visible and OS.has_feature("editor"):
					SOL.debug_console()
	if event.is_action_pressed("small_screenshot"):
		DIR.screenshot(true)
	elif event.is_action_pressed("screenshot"):
		DIR.screenshot(false)
	# the options menu is shown and hidden when esc is pressed
	if event.is_action_pressed("escape"):
		# just close the save screen and not open OPT when save screen is open
		for i in ["save_screen", "debug_console", "overworld_menu"]:
			if i in DAT.player_capturers:
				return
		if not root.visible:
			root.show()
			top_text = -1
			_on_top_text_switcher_timeout()
			get_tree().paused = true
			cur_opt = 0
			select(cur_opt)
			options_open = true
		else:
			save_options()
			root.hide()
			get_tree().paused = false
			options_open = false
	if not root.visible:
		return
	if event is InputEventJoypadMotion:
		return
	# moving around the menu
	var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").round()
	var last_opt := cur_opt
	cur_opt = wrapi(cur_opt + int(move.y), 0, options_length)
	if cur_opt != last_opt:
		SND.menusound()
	select(cur_opt)
	modify(move.x)


func save_options() -> void:
	for c in IONS.keys():
		var value = get_opt(c)
		opt.set_value(c, "value", value)
	opt.save(OPTION_PATH)


func load_options() -> void:
	for o in IONS.keys():
		var value: float = opt.get_value(o, "value", get_opt_default(o))
		set_opt(o, value)
	for y in options_length:
		cur_opt = y
		modify(0, false, true)


func select(opti: int) -> void:
	var opt_contain := get_option_nodes()
	main_container.position.y = 2
	for c in opt_contain:
		c.modulate = Color.WHITE
	opt_contain[opti].modulate = Color.CYAN
	set_opt("view_keybinds", 0.0)
	keybinds.hide()
	# this is the custom scrolling implementation since scrollcontainer
	# would've needed me to use the default focus system as well
	# which i find unreliable at this point sadly
	var location: Vector2 = opt_contain[opti].get_global_transform_with_canvas().origin
	while location.y > 103:
		main_container.position.y -= 1
		location = opt_contain[opti].get_global_transform_with_canvas().origin
	while location.y < 15:
		main_container.position.y += 1
		location = opt_contain[opti].get_global_transform_with_canvas().origin


# changing the value of an option
func modify(a: float, reset := false, ifset := false) -> void:
	var amt := signf(a)
	var opt_contain := get_option_nodes()
	var container := opt_contain[cur_opt]
	var type: String = container.get_meta("type", "")
	var end_value = clamp(
			get_opt(type) + amt * get_opt_step(type),
			get_opt_min(type), get_opt_max(type))
	var prev_opt: Variant = get_opt(type)
	if not ifset:
		set_opt(type, end_value)
	if reset:
		set_opt(type, get_opt_default(type))
		prev_opt = get_opt(type)
	update(container)
	# here we go changing the actual things
	AudioServer.set_bus_volume_db(0, get_opt("main_volume"))
	AudioServer.set_bus_volume_db(1, get_opt("music_volume"))
	AudioServer.set_bus_volume_db(4, get_opt("music_volume"))
	Engine.max_fps = get_opt("max_fps")
	if prev_opt == get_opt(type):
		return
	match type:
		"reset":
			reset_options()
			SND.play_sound(preload("res://sounds/hurt.ogg"), {volume = 4.0})
		"main_volume":
			SND.menusound(1.76)
		"music_volume":
			SND.play_sound(preload("res://sounds/gui.ogg"), {bus = "Music", pitch = 0.89})
		"screen_shake_intensity":
			SOL.shake(1.0)
			SND.menusound(1.36)
		"battle_text_opacity":
			SND.menusound(1.36)
			battle_text_opacity_changed.emit()
		"less_fancy_graphics":
			get_tree().call_group(
					"_fancy_graphics_option_owners",
					"_set_fancy_grapics_to",
					not bool(end_value))
		"view_keybinds":
			keybinds.visible = bool(end_value)
		_:
			SND.menusound(1.36)


# all visual option nodes are stored in a container node
# the first child is the name of the option
# the second one is the value of the option
func update(container: Container) -> void:
	container.get_child(0).text = str(container.get_meta("type")).replace("_", " ")
	container.get_child(1).text = str(snapped(get_opt(container.get_meta("type")), 0.01))


func gen_option_nodes() -> void:
	options_length = 0
	for i in CATEGORIES.keys():
		var opts := CATEGORIES[i] as Array
		var label := Label.new()
		main_container.add_child(label)
		label.text = "  " + i
		for j in opts:
			var option := base_option.duplicate()
			main_container.add_child(option)
			option.show()
			option.set_meta("type", str(j))
			update(option)
			options_length += 1


# get all option visual containers, ignoring the category section labels
func get_option_nodes() -> Array[Node]:
	var opt_contain := main_container.get_children()
	for o in opt_contain:
		if not o is Container:
			opt_contain.erase(o)
	return opt_contain


# get various aspects of the stored option value
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


# and set options
func set_opt(key: String, to: Variant) -> void:
	IONS[key]["value"] = to


func reset_options() -> void:
	for o in options_length:
		cur_opt = o
		modify(-1, true)


# display interesting stuff at the top of the options menu
func _on_top_text_switcher_timeout() -> void:
	if not root.visible: return
	top_text = wrapi(top_text + 1, 0, 3)
	var text := ""
	match top_text:
		0:
			text = "game paused - options menu"
		1:
			text = "music: %s" % SND.current_song.get("title", "nothing")
		2:
			text = "minutes played: %s" % roundi(DAT.playtime / 60.0)
	top_text_label.text = text
