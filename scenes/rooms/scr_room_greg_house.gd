extends Room

const CarType := preload("res://scenes/decor/scr_overworld_car.gd")
const DoorType := preload("res://scenes/decor/scr_door_area.gd")

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
@onready var house_door := $Areas/HouseDoor as DoorType
@onready var next_to_car_pos: Marker2D = $Cutscenes/NextToCarPos
@onready var car_inspect: InspectArea = $Cutscenes/ZermCar/InspectArea


func _ready() -> void:
	super()
	if intro_progress == 0 and LTS.gate_id == &"intro":
		start()
		SOL.dialogue("intro_convo_2")
	elif intro_progress == 1:
		leave_house()
	elif intro_progress == 2:
		evicted()
	elif intro_progress == 3:
		after_battle()
	else:
		DAT.set_data("intro_cutscene_over", true)
		$Cutscenes.queue_free()


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
	zerma.time_moved_limit = 400


func evicted() -> void:
	leave_house()
	house_door.destination = ""
	zerma.default_lines.clear()
	zerma.default_lines.append("zerma_fight_preface")
	zerma.move_to(zerma_walk_pos_2.global_position)
	zerma.inspected.connect(func():
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == "yes":
				SOL.dialogue_choice = ""
				LTS.enter_battle(preload("res://resources/battle_infos/zerma_tutorial.tres"))
				intro_progress += 1
			elif SOL.dialogue_choice == "no":
				DAT.set_data("got_battle_tutorial", false)
				SOL.dialogue_choice = ""
				move_to_car()
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func after_battle() -> void:
	leave_house()
	house_door.destination = ""
	zerma.global_position = zerma_walk_pos_2.global_position
	SOL.dialogue("zerma_after_fight")
	SOL.dialogue_closed.connect(move_to_car, CONNECT_ONE_SHOT)


func move_to_car() -> void:
	zerma.default_lines.clear()
	zerma.default_lines.append("zerma_goodbye")
	zerma.move_to(next_to_car_pos.global_position)
	car_inspect.queue_free()
	enable_gates()
	intro_progress = 4
	zerma.inspected.connect(func():
		SOL.dialogue_closed.connect(func():
			zerma.move_to(car_stop_pos.global_position)
			zerma.set_collision_mask_value(1, false)
			zerma.target_reached.connect(func():
				greg.saving_disabled = false
				zerma.hide()
				set_car_noise(true)
				zerm_car.turn(Math.ANGLE_RIGHT)
				var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
				tw.tween_property(zerm_car, "global_position", zerma.global_position + Vector2(429, 5), 2)
				tw.parallel().tween_property(zerma, "global_position",
						zerma.global_position + Vector2(429, 5), 2)
				tw.parallel().tween_property(vroom_vroom, "pitch_scale", 1.2, 2).from(0.75)
				tw.tween_callback(func(): set_car_noise(false))
			)
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


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
	[$Areas/RoomGate, $Areas/RoomGate2, $Areas/RoomGate3].map(func(a): a.disabled = true)


func enable_gates() -> void:
	[$Areas/RoomGate, $Areas/RoomGate2, $Areas/RoomGate3].map(func(a): a.disabled = false)
