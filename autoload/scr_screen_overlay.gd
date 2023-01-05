extends CanvasLayer

# screen layer over everything else. used for things like UI

signal fade_finished

@export var show_fps := false
var fps_label : Label

@onready var dialogue_box := $DialogueBoxOrderer
@onready var screen_fade : ColorRect = $ScreenFadeOrderer/ScreenFade


func _ready() -> void:
	if show_fps:
		fps_label = Label.new()
		add_ui_child(fps_label, 120, false)
	screen_fade.get_parent().hide()


func _input(_event: InputEvent) -> void:
	if show_fps and is_instance_valid(fps_label):
		fps_label.text = str(Engine.get_frames_per_second())


func dialogue(key: String) -> void:
	dialogue_box.prepare_dialogue(key)


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


