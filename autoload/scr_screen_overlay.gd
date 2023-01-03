extends CanvasLayer

@export var show_fps := false
var fps_label : Label

@onready var dialogue_box := $DialogueBoxOrderer


func _ready() -> void:
	if show_fps:
		fps_label = Label.new()
		add_ui_child(fps_label, 120, false)


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

