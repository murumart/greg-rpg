extends Room

const CarType := preload("res://scenes/decor/scr_overworld_car.gd")

var intro_progress := 0:
	get:
		return DAT.get_data("intro_progress", 0)
	set(to):
		DAT.set_data("intro_progress", to)

@onready var greg := $Greg as PlayerOverworld
@onready var camera: Camera2D = $Greg/Camera
@onready var zerma := $Cutscenes/Zerma as OverworldCharacter
@onready var zerm_car := $Cutscenes/ZermCar as CarType
@onready var car_stop_pos: Marker2D = $Cutscenes/CarStopPos
@onready var zerma_walk_pos: Marker2D = $Cutscenes/ZermaWalkPos
@onready var zerma_walk_pos_2: Marker2D = $Cutscenes/ZermaWalkPos2
@onready var vroom_vroom: AudioStreamPlayer2D = $Cutscenes/ZermCar/VroomVroom


func _ready() -> void:
	super()
	if intro_progress == 0:
		start()
		SOL.dialogue("intro_convo_2")
	elif intro_progress == 1:
		leave_house()


func _physics_process(delta: float) -> void:
	pass


func start() -> void:
	delete_escape_routes()
	delete_nuisances()
	DAT.capture_player("cutscene")
	greg.hide()
	# camera follows car
	greg.remove_child(camera)
	zerm_car.add_child(camera)
	zerm_car.turn(Math.ANGLE_LEFT)
	camera.global_position = zerm_car.global_position
	set_car_noise(true)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(zerm_car, "global_position", car_stop_pos.global_position, 6.0)
	tw.parallel().tween_property(vroom_vroom, "pitch_scale", 0.75, 6.0).from(1.3)
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		set_car_noise(false)
		greg.show()
		greg.global_position = zerm_car.global_position + Vector2(0, -5)
		zerma.show()
		zerma.global_position = zerm_car.global_position + Vector2(0, 10)
		await create_tween().tween_interval(0.5).finished
		zerm_car.remove_child(camera)
		greg.add_child(camera)
		zerma.move_to(zerma.global_position + Vector2(20, 0))
		zerma.target_reached.connect(func():
			zerma.move_to(zerma_walk_pos.global_position)
			zerma.target_reached.disconnect(zerma.target_reached.get_connections()[0].callable)
		, CONNECT_DEFERRED)
		zerma.default_lines.append("intro_inspect_zerma_1")
		greg.animate("walk_up")
		tw = create_tween()
		tw.tween_property(greg, "global_position:y", greg.global_position.y - 20, 3.5)
		SOL.dialogue("intro_convo_3")
		SOL.dialogue_box.started_speaking.connect(line_by_line)
		SOL.dialogue_closed.connect(func():
			tw = create_tween().set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(camera, "global_position", greg.global_position, 2.0)
			tw.parallel().tween_property(camera, "position:y", -8, 2.0)
			tw.tween_callback(func():
				SOL.dialogue("intro_convo_4")
				SOL.dialogue_closed.connect(func():
					DAT.free_player("cutscene")
					greg.direct_animation()
					intro_progress = 1
				, CONNECT_ONE_SHOT)
			)
		, CONNECT_ONE_SHOT)
	)


func leave_house() -> void:
	delete_escape_routes()
	delete_nuisances()
	zerma.global_position = zerma_walk_pos.global_position
	zerma.default_lines.append("intro_inspect_zerma_2")
	zerma.show()
	zerm_car.global_position = car_stop_pos.global_position
	zerm_car.turn(Math.ANGLE_LEFT)


func set_car_noise(b: bool) -> void:
	vroom_vroom.playing = b


func line_by_line(line: int) -> void:
	if line == 1:
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(camera, "global_position", Vector2(0, 48), 2)
		SOL.dialogue_box.started_speaking.disconnect(line_by_line)


func delete_nuisances() -> void:
	[$Areas/CatSpawners/Cats1, $Areas/CatSpawners/Cats2, $Areas/CatSpawners/Cats3, $Areas/CatSpawners/Cats4, $Areas/CatSpawners/Cats5, $Areas/CatSpawners/Cats6].map(func(a): a.queue_free())


func delete_escape_routes() -> void:
	[$Areas/RoomGate, $Areas/RoomGate2, $Areas/RoomGate3].map(func(a): a.queue_free())
