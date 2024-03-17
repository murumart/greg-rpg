extends Node2D

const SPEED := 95

@onready var world := $OverworldTiles
@onready var car := $ZermCar
@onready var trees := $Trees
var tree_load := preload("res://scenes/decor/scn_tree.tscn")
@onready var cars := $Cars
const CAR := preload("res://scenes/decor/scn_overworld_car.tscn")

@onready var ui := $UiGroup
@onready var logo := $UiGroup/UI/Logo
@onready var title := $UiGroup/UI/Title
@onready var animator := $BeginningAnimation


func _ready() -> void:
	ResMan.get_character("greg").inventory.erase("cellphone")
	car.turn(PI / 2)
	car.moves = false
	car.position.y = -80

	SND.play_song("arent_you_excited", 2931, {play_from_beginning = true, save_audio_position = false})

	await animator.animation_finished

	var tw := create_tween()
	tw.tween_property(car, "position:y", 0.0, 1.0)
	await tw.step_finished
	SOL.dialogue("intro_convo_0")
	await SOL.dialogue_closed
	intro_part_2()


func intro_part_2() -> void:
	animator.play("part2")
	SOL.dialogue("intro_spection_1")
	await SOL.dialogue_closed
	animator.play("part3")
	SOL.dialogue("intro_spection_2")
	await SOL.dialogue_closed
	animator.play("part4")
	await animator.animation_finished

	SOL.dialogue("intro_convo_1")
	await SOL.dialogue_closed
	exit_intro()


func exit_intro() -> void:
	var tw := create_tween()
	tw.tween_property(car, "position:y", 180, 2.0)
	await tw.step_finished
	SND.play_song("birds", 0.05)
	LTS.gate_id = &"intro"
	LTS.level_transition("res://scenes/rooms/scn_room_greg_house.tscn", {fade_speed = 0.05})


func _physics_process(delta: float) -> void:
	world.position.y = roundi(wrapf(world.position.y - SPEED * delta, 0, 16))

	for t in trees.get_children():
		t.position.y -= SPEED * delta * 1.265
		if t.position.y <= -64:
			t.queue_free()

	for t in cars.get_children():
		t.position.y -= SPEED * delta * 2
		if t.position.y <= -80:
			t.queue_free()

	if Engine.get_physics_frames() % 16 == 0:
		spawn_tree()

	var input := Input.get_axis("ui_left", "ui_right")
	car.position.x = clampf(car.position.x + input, -38, -16)


func spawn_tree() -> void:
	var tree := tree_load.instantiate()
	trees.add_child(tree)
	tree.position.y = 180
	tree.position.x = randf_range(-96, -56) if bool(randi() % 2) else randf_range(40, 80)
	tree.type = randi() % tree.TYPES_SIZE

	if randf() < 0.1:
		var c := CAR.instantiate()
		c.color = Color(randf()/2.0, randf()/2.0, randf()/2.0)
		c.moves = false
		c.disable_saving = true
		cars.add_child(c)
		c.turn(PI * 1.5)
		c.position.y = 180
		c.position.x = randf_range(0, 24)
		c.moves = false
