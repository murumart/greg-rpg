extends Node2D

signal finished

@export var star_count := 30
@export var radius := 64
@export var disks: Array[Node2D]
@export var camera: Camera2D

@onready var ui: Control = $Ui
@onready var clicking: AudioStreamPlayer = $Clicking

var _rng: RandomNumberGenerator
var _star_positions: PackedVector2Array
var _active := false
var _selected_disk: int
var _correct_disks: int
var _correct_num: int


func _ready() -> void:
	assert(disks.size() > 0)
	$InteractionArea.interacted.connect(_interacted)
	remove_child(ui)
	SOL.add_ui_child(ui)
	ui.hide()
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(DAT.get_data("nr", 0.0) * 1000 + hash(LTS.get_current_scene().name))
	for x in star_count:
		_star_positions.append(Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0, radius))

	var stars_left := star_count
	while stars_left > 0:
		var st := Sprite2D.new()
		st.region_enabled = true
		st.texture = preload("res://sprites/world/sg/stars.png")
		st.region_rect.position = Vector2(randi_range(0, 2), randi_range(0, 2)) * 5
		st.region_rect.size = Vector2(5, 5)
		st.material = preload("res://resources/add_material.tres")
		st.position = _star_positions[stars_left - 1]
		disks[_selected_disk].add_child(st)
		_selected_disk = wrapi(_selected_disk + 1, 0, disks.size())
		stars_left -= 1
	for d in disks:
		d.rotation_degrees = _rng.randf_range(25, 270)
		_unrotate_children(d)
	for x in disks.size():
		_correct_num |= 1 << x
	_highlight_disks()


func _draw() -> void:
	draw_circle(Vector2(0, 0), radius, Color(Color.BLACK, 0.7))
	for d in _star_positions:
		draw_circle(d, 2, Color.BLACK)


func _interacted() -> void:
	DAT.capture_player("minigame")
	ui.show()
	var tw := create_tween()
	tw.tween_property(camera, ^"global_position", self.global_position, 0.5)
	tw.tween_callback(func() -> void:
		_active = true
		_highlight_disks()
	)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"cancel"):
		_active = false
		_highlight_disks()
		var tw := create_tween()
		tw.tween_property(camera, ^"position", Vector2(0, -9), 0.5)
		tw.tween_callback(func() -> void:
			DAT.free_player("minigame")
			ui.hide()
		)
		get_window().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_accept"):
		_selected_disk = wrapi(_selected_disk + 1, 0, disks.size())
		SND.play_sound(preload("res://sounds/misc_click.ogg"))
		_highlight_disks()
	_rotate_disk(Input.get_axis(&"move_left", &"move_right"))
	if _correct_disks == _correct_num:
		print("starmapo done")
		finished.emit()
	get_window().set_input_as_handled()


func _rotate_disk(amt: float) -> void:
	if not amt:
		return
	var speed := 0.04
	var grace := 7.0
	var disk := disks[_selected_disk]
	var rot := wrapf(disk.rotation_degrees, 0, 360.0)
	if absf(rot) <= grace:
		speed = 0.015
	disk.rotate(amt * speed)
	if absf(rot) < grace * 0.3:
		var old := _correct_disks
		_correct_disks |= (1 << _selected_disk)
		if _correct_disks != old:
			SND.play_sound(preload("res://sounds/skating/s13.ogg"), {pitch_scale = 1.5})
	else:
		_correct_disks &= ~(1 << _selected_disk)
	_highlight_disks()
	_unrotate_children(disk)
	clicking.play()


func _highlight_disks() -> void:
	for d in disks.size():
		var disk := disks[d]
		var current := d == _selected_disk and _active
		var correct := bool(_correct_disks & (1 << d))
		var color := Color(Color.DARK_TURQUOISE, 0.5)
		if correct:
			color = Color(Color.GOLD, 0.75)
			if current: color = Color.GOLD.lightened(0.75)
		elif current:
			color = Color.WHITE
		disk.modulate = color


func _unrotate_children(n: Node2D) -> void:
	for c in n.get_children():
		if c is Node2D:
			c.global_rotation = 0.0
