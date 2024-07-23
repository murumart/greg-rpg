extends CanvasLayer

# screen layer over everything else. used for things like UI

signal fade_finished
signal dialogue_closed # this is used very often

const SCREEN_SIZE := Vector2(160, 120)
const HALF_SCREEN_SIZE := Vector2(80, 60)
const SCREEN_CENTER := HALF_SCREEN_SIZE

@export var show_fps := false
var fps_label: Label

var speaking := false
var dialogue_open := false

var save_menu_open := false

@onready var dialogue_box: DialogueBox = $DialogueBox as DialogueBox
@onready var screen_fade_order := $ScreenFadeOrderer

var dialogue_choice := &""
var effects_dict := {}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	dialogue_box.dialogue_closed.connect(_on_dialogue_closed)
	dialogue_box.started_speaking.connect(_on_speaking_started)
	dialogue_box.finished_speaking.connect(_on_speaking_stopped)
	if show_fps:
		fps_label = Label.new()
		fps_label.theme = preload("res://resources/thm_main_ui.tres")
		add_ui_child(fps_label, 120, false)


func _input(_event: InputEvent) -> void:
	if show_fps and is_instance_valid(fps_label):
		fps_label.text = str(Engine.get_frames_per_second())


# speak a dialogue
func dialogue(key: String) -> void:
	var player: PlayerOverworld = get_tree().get_first_node_in_group("players")
	if is_instance_valid(player) and DAT.player_capturers.is_empty():
		# position the dialogue box up or down so the player is visible
		var pos := player.get_global_transform_with_canvas().origin
		if pos.y < 75:
			dialogue_low_position()
		else:
			dialogue_high_position()
	dialogue_box.prepare_dialogue(key)


func dialogue_exists(key: String) -> bool:
	if dialogue_box.dialogues_dict.is_empty():
		dialogue_box.load_dialogue_dict()
	return key in dialogue_box.dialogues_dict


func _on_dialogue_closed() -> void:
	dialogue_open = false
	dialogue_closed.emit() # so much logic hinges on this single line


# these are used in some places i guess
func _on_speaking_started(_line := 0) -> void:
	speaking = true
	dialogue_open = true


func _on_speaking_stopped(_line := 0) -> void:
	speaking = false


# when a node needs to be at the top of the world
func add_ui_child(node: Node, custom_z_index := 0, delete_on_scene_change := true) -> void:
	var node2d := Node2D.new()
	add_child(node2d)
	node2d.z_index = custom_z_index
	# remove them on scene change since they are no longer attached to their
	# original scenes
	if delete_on_scene_change:
		node2d.add_to_group("free_on_scene_change")
	node2d.add_child(node)


func dialogue_low_position() -> void:
	dialogue_box.position.y = 92
	$DialogueBox/DialogueBoxPanel/ScrollContainer.position.y = -35


func dialogue_high_position() -> void:
	dialogue_box.position = Vector2.ZERO
	$DialogueBox/DialogueBoxPanel/ScrollContainer.position.y = 35


func fade_screen(start: Color, end: Color, time := 1.0) -> void:
	var tw := create_tween()
	var rect := ColorRect.new()
	rect.size = SCREEN_SIZE
	rect.color = start
	screen_fade_order.add_child(rect)
	tw.tween_property(rect, "color", end, time)
	if end.a <= 0.0:
		tw.tween_callback(func():
			rect.queue_free()
		)
	tw.tween_callback(func():
		self.fade_finished.emit()
		if is_instance_valid(rect):
			rect.queue_free()
	)


# simpler access to shake the camera
func shake(amt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not is_instance_valid(cam): return
	if cam.has_method("add_trauma"):
		cam.add_trauma(amt)


# opening the saving/loading menu
func save_menu(loading := false, options := {}) -> void:
	var savemenu := preload("res://scenes/gui/scn_save_screen.tscn").instantiate()
	savemenu.position += Vector2(SOL.SCREEN_SIZE / 2)
	savemenu.init(options)
	add_ui_child(savemenu)
	if loading: savemenu.set_mode(savemenu.LOAD)
	DAT.capture_player("save_screen")


func debug_console() -> void:
	if "debug_console" in DAT.player_capturers: return
	var cnsole := load("res://scenes/gui/scn_console.tscn").instantiate() as DebugConsole
	#cnsole.position += Vector2(SOL.SCREEN_SIZE / 2)
	add_ui_child(cnsole, 0, false)
	DAT.capture_player("debug_console")


func vfx_damage_number(pos: Vector2, text: String, color := Color.WHITE, size := 1.0, options := {}) -> void:
	var o := {"text": text, "size": size, "color": color}
	o.merge(options)
	vfx("damage_number", pos, o)


# spawn vfx effects
func vfx(nomen: StringName, pos := Vector2(), options := {}) -> Node:
	# the nomen must be the filenam
	var effect: Node2D = effects_dict.get(nomen, load("res://scenes/vfx/scn_vfx_%s.tscn" % nomen)).instantiate()
	effect.z_index = options.get("z_index", 100)
	# can specify custom parent node to the effect, defaults to this here SOL
	var parent: Node = options.get("parent", self)
	parent.add_child(effect)
	effect.add_to_group("vfx")
	# option to silence
	if options.get("silent", false):
		for i in get_all_children_of_type(effect, "AudioStreamPlayer"):
			i = i as AudioStreamPlayer
			i.volume_db = -80
			i.bus = "Master"
		for i in get_all_children_of_type(effect, "AudioStreamPlayer2D"):
			i.queue_free()
			i = i as AudioStreamPlayer2D
			i.volume_db = -80
			i.bus = "Master"
	# some effects have scripts, this is where they are called
	if effect.has_method(&"init"):
		effect.init(options)
	# this solution was found after much testing.
	# not perfect...
	if not "global_position" in parent:
		effect.global_position = pos + SCREEN_SIZE / 2.0
	else:
		effect.global_position = pos

	#effect.global_position = pos
	if options.get("random_rotation", false):
		effect.rotation = randf_range(-TAU, TAU)
	effect.scale = options.get("scale", Vector2(1, 1))
	# most effects have queue_free() calls built into their animations
	if options.get("free_time", -1.0) > 0:
		get_tree().create_timer(options.get("free_time")).timeout.connect(
			func():
				effect.queue_free()
		, CONNECT_ONE_SHOT)
	return effect


func clear_vfx() -> void:
	for i in get_tree().get_nodes_in_group("vfx"):
		i.queue_free()


func get_all_children_of_type(node: Node, type: String) -> Array:
	var nods := []
	for c in node.get_children():
		if c.get_class() == type:
			nods.append(c)
		if c.get_child_count() > 0:
			nods.append_array(get_all_children_of_type(c, type))
	return nods


# maybe it caches them somewhere so it will be less laggy than loading it during runtime
func load_all_effects() -> void:
	if not effects_dict.is_empty():
		return
	var time := Time.get_ticks_msec()
	var path := "res://scenes/vfx/"
	var names := DIR.get_dir_contents(path)
	for file in names:
		if not file.begins_with("scn_vfx"):
			continue
		var fpath := path + file + ".tscn"
		if ResourceLoader.exists(fpath):
			var scene := load(fpath)
			effects_dict[file.trim_prefix("scn_vfx_")] = scene
	print("loading effects took ", Time.get_ticks_msec() - time, " ms")
