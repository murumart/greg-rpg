extends CanvasLayer

# screen layer over everything else. used for things like UI

signal fade_finished
signal dialogue_closed

const SCREEN_SIZE := Vector2i(160, 120)

@export var show_fps := false
var fps_label : Label

var speaking := false
var dialogue_open := false

@onready var dialogue_box : DialogueBox = $DialogueBoxOrderer
@onready var screen_fade : ColorRect = $ScreenFadeOrderer/ScreenFade

var dialogue_choice := &""


func _init() -> void:
	pass


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	dialogue_box.dialogue_closed.connect(_on_dialogue_closed)
	dialogue_box.started_speaking.connect(_on_speaking_started)
	dialogue_box.finished_speaking.connect(_on_speaking_stopped)
	if show_fps:
		fps_label = Label.new()
		fps_label.theme = preload("res://resources/thm_main_ui.tres")
		add_ui_child(fps_label, 120, false)
	screen_fade.get_parent().hide()


func _input(_event: InputEvent) -> void:
	if show_fps and is_instance_valid(fps_label):
		fps_label.text = str(Engine.get_frames_per_second())


func dialogue(key: String) -> void:
	dialogue_box.prepare_dialogue(key)


func _on_dialogue_closed() -> void:
	dialogue_closed.emit()
	dialogue_open = false


func _on_speaking_started() -> void:
	#print("started speaking")
	speaking = true
	dialogue_open = true


func _on_speaking_stopped() -> void:
	#print("stopped speaking")
	speaking = false


func add_ui_child(node: Node, custom_z_index := 0, delete_on_scene_change := true) -> void:
	var node2d := Node2D.new()
	add_child(node2d)
	node2d.z_index = custom_z_index
	if delete_on_scene_change: node2d.add_to_group("free_on_scene_change")
	node2d.add_child(node)


func fade_screen(start: Color, end: Color, time := 1.0) -> void:
	var tw := create_tween()
	screen_fade.get_parent().show()
	screen_fade.color = start
	tw.tween_property(screen_fade, "color", end, time)
	if end.a < 0.5:
		tw.tween_property(screen_fade.get_parent(), "visible", false, 0.0)
	tw.tween_callback(emit_signal.bind("fade_finished"))


func shake(amt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not is_instance_valid(cam): return
	if cam.has_method("add_trauma"):
		cam.add_trauma(amt)


func save_menu(loading := false, options := {}) -> void:
	var savemenu := preload("res://scenes/gui/scn_save_screen.tscn").instantiate()
	savemenu.position += Vector2(SOL.SCREEN_SIZE / 2)
	savemenu.init(options)
	add_ui_child(savemenu)
	if loading: savemenu.set_mode(savemenu.LOAD)
	DAT.capture_player("save_screen")


func vfx_dustpuff(pos: Vector2) -> void:
	vfx("dustpuff", pos)


func vfx_bangspark(pos: Vector2) -> void:
	vfx("bangspark", pos, {"random_rotation": true})


func vfx(nomen: String, pos := Vector2(), options := {}) -> void:
	var effect : Node2D = load("res://scenes/vfx/scn_vfx_%s.tscn" % nomen).instantiate()
	effect.z_index = 100
	var parent : Node = options.get("parent", self)
	parent.add_child(effect)
	if effect.has_method(&"init"):
		effect.init(options)
	effect.global_position = pos + SCREEN_SIZE / 2.0 if not "global_position" in parent else pos
	if options.get("random_rotation", false):
		effect.rotation = randf_range(-TAU, TAU)
	if options.get("free_time", -1.0) > 0:
		await get_tree().create_timer(options.get("free_time")).timeout
		effect.queue_free()
