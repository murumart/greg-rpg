extends Node2D

signal finished

@export var star_count := 30
@export var radius := 64
@export_range(1, 8, 1.0) var disk_count: int = 1
@export var camera: Camera2D

@onready var ui: Control = $Ui
@onready var clicking: AudioStreamPlayer = $Clicking
@onready var disk_nr_label: Label = $Ui/DiskNrLabel

var _rng: RandomNumberGenerator
var _stars: Array[Sprite2D]
var _active := false
var _disks: Array[Node2D]
var _selected_disk: int
var _correct_disks: int
var _correct_num: int
var _solved := false


func _ready() -> void:
	assert(disk_count > 0)
	$InteractionArea.interacted.connect(_interacted)
	remove_child(ui)
	SOL.add_ui_child(ui)
	ui.hide()
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(DAT.get_data("nr", 0.0) * 1000 + hash(LTS.get_current_scene().name))
	for __ in disk_count:
		var d := Node2D.new()
		add_child(d)
		_disks.append(d)
	var stars_left := star_count
	while stars_left > 0:
		var st := Sprite2D.new()
		st.region_enabled = true
		st.texture = preload("res://sprites/world/sg/stars.png")
		st.region_rect.position = Vector2(randi_range(0, 2), randi_range(0, 2)) * 5
		st.region_rect.size = Vector2(5, 5)
		st.material = preload("res://resources/add_material.tres")
		st.position = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0, radius)
		st.position = st.position.round()
		_disks[_selected_disk].add_child(st)
		_stars.append(st)
		_selected_disk = wrapi(_selected_disk + 1, 0, disk_count)
		stars_left -= 1
	for d in _disks:
		d.rotation_degrees = _rng.randf_range(25, 270)
		_unrotate_children(d)
	for x in disk_count:
		_correct_num |= 1 << x
	_selected_disk = 0
	_highlight_disks()


func _draw() -> void:
	const starsize := Vector2(5, 5)
	draw_circle(Vector2(0, 0), radius, Color(Color.BLACK, 0.7))
	for d in _stars:
		#draw_circle(d.position, 5.0, Color.RED, false)
		draw_texture_rect_region(
				d.texture,
				Rect2(d.position - starsize * 0.5, starsize),
				d.region_rect,
				Color.BLACK
		)

func _interacted() -> void:
	DAT.capture_player("minigame")
	ui.show()
	var tw := create_tween()
	tw.tween_property(camera, ^"global_position", self.global_position, 0.5)
	tw.tween_callback(func() -> void:
		_active = true
		_highlight_disks()
	)


var _hurry := 0.0
var _inertia := 0.0

func _process(delta: float) -> void:
	const speed := 2.5
	if not _active or _solved:
		return
	var rotinput := Input.get_axis(&"move_left", &"move_right") * delta * speed
	if rotinput == 0:
		_hurry = move_toward(_hurry, 0.5, delta * 32)
		_inertia = move_toward(_inertia, 0.0, delta * ease(0.5 / _hurry, -4.0))
	else:
		_hurry = move_toward(_hurry, 30.0, delta * 4)
		_inertia = move_toward(_inertia, rotinput, delta * 32)
	_rotate_disk(_inertia, _selected_disk, _hurry)
	for i in range(_selected_disk + 1, disk_count):
		_rotate_disk(_inertia / pow(_selected_disk - i, 2), i, _hurry)


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
		_selected_disk = wrapi(_selected_disk + 1, 0, disk_count)
		SND.play_sound(preload("res://sounds/misc_click.ogg"))
		_highlight_disks()
	if event.is_action_pressed(&"hide_battle_ui"):
		_twinkle()
	get_window().set_input_as_handled()


func _rotate_disk(direction: float, disk: int, speed: float) -> void:
	if not direction or _solved:
		return
	#var speed := 0.04
	const grace := 7.0
	#var disk := _disks[_selected_disk]
	var rot := wrapf(_disks[disk].rotation_degrees, 0, 360.0)
	#if absf(rot) <= grace and current:
	#	speed = 0.015
	_disks[disk].rotate(direction * speed)
	if absf(rot) < grace * 0.18 and speed <= 1.5:
		var old := _correct_disks
		_correct_disks |= (1 << disk)
		_disks[disk].rotation = 0.0
		if _correct_disks != old:
			SND.play_sound(preload("res://sounds/skating/s13.ogg"), {pitch_scale = 1.5})
	else:
		_correct_disks &= ~(1 << disk)
	_highlight_disks()
	_unrotate_children(_disks[disk])
	clicking.play()
	if _correct_disks == _correct_num:
		_solved = true
		print("starmapo done")
		finished.emit()
		_twinkle()


func _highlight_disks() -> void:
	disk_nr_label.text = "disk nr " + str(_selected_disk + 1) + "/" + str(disk_count)
	for d in disk_count:
		var disk := _disks[d]
		var current := d == _selected_disk and _active
		var correct := bool(_correct_disks & (1 << d))
		var color := Color(Color.DARK_TURQUOISE, 0.5)
		if correct:
			color = Color(Color.GREEN, 0.75)
			if current: color = Color.GREEN.lightened(0.75)
		elif current:
			color = Color.WHITE
		disk.modulate = color


func _unrotate_children(n: Node2D) -> void:
	for c in n.get_children():
		if c is Node2D:
			c.global_rotation = 0.0


func _twinkle() -> void:
	var stars := _stars.duplicate()
	stars.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.x + a.global_position.y < b.global_position.x + b.global_position.y
	)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel()
	const wait := 0.15
	const color := Color(0, 0, 6.0)
	var i := 0
	for s: Node2D in stars:
		#tw.tween_interval(wait * i)
		tw.tween_property(s, ^"modulate", color, wait).from(Color.WHITE).set_ease(Tween.EASE_IN).set_delay(wait * i)
		#tw.tween_interval(wait * i + 0.1)
		tw.tween_property(s, ^"modulate", Color.WHITE, wait + i * 0.1).from(color).set_ease(Tween.EASE_OUT).set_delay((wait * i) * 2)
		i += 1
