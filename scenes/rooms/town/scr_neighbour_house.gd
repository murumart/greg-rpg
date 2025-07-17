extends Node2D

const CAR_SCARED_DIED := &"car_scared_overrun"
const FENCE_DESTROYED := &"fence_destroyed"

const NEIGHBOUR_WIFE_CYCLE := 470
const GreenhouseType := preload("res://scenes/decor/scr_greenhouse.gd")

@onready var neighbour_wife := $NeighbourWife as OverworldCharacter
@onready var greenhouse := $NeighboursGreenhouse as GreenhouseType
@onready var car_scared := $CarScared as OverworldCharacter
@onready var greg := $"../../Greg" as PlayerOverworld
@onready var car_inspect: InspectArea = $Car/InspectArea

@onready var fence_destroy_area: Area2D = $OverworldTiles/Fence2/FenceDestroyArea
@onready var fence_2: TileMapLayer = $OverworldTiles/Fence2
@onready var fence_inspect: InspectArea = $OverworldTiles/FenceInspect


func _ready() -> void:
	neighbour_wife_position()
	neighbour_wife.inspected.connect(nwife_talk)
	car_scared.inspected.connect(car_scared_inspected)
	if DAT.seconds > 3600:
		car_scared.default_lines.clear()
		car_scared.default_lines.append("car_scared_long")

	if DAT.get_data(FENCE_DESTROYED, false):
		fence_inspect.key = "fence_carful"
		fence_2.queue_free()
	if DAT.get_data(CAR_SCARED_DIED, false):
		car_scared.queue_free()
	if randf() < 0.2 and DAT.seconds > 600:
		car_inspect.keys = ["neighbour_car_3"]
	fence_destroy_area.body_entered.connect(_destroy_fence.unbind(1))


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(car_scared):
		return
	if car_scared.global_position.x > -125 and car_scared.is_physics_processing():
		_car_scared_run_over()


func nwife_talk() -> void:
	var time_diff := DAT.seconds - DAT.get_data(
		greenhouse.get_save_key("vegs_eaten_second"), -123812391) as int
	if time_diff <= 15:
		neighbour_wife.convo_progress = 0
		neighbour_wife.default_lines.clear()
		neighbour_wife.default_lines.append("neighbour_wife_ate_greenhouse")
		neighbour_wife.default_lines.append("neighbour_wife_ate_greenhouse_2")
		neighbour_wife.inspected.disconnect(
			neighbour_wife.inspected.get_connections()[0]["callable"])


func neighbour_wife_position() -> void:
	var time := wrapi(DAT.seconds, 0, NEIGHBOUR_WIFE_CYCLE)
	if time > (NEIGHBOUR_WIFE_CYCLE / 2.0) and LTS.gate_id != &"house-town":
		neighbour_wife.queue_free()


func car_scared_inspected() -> void:
	SOL.dialogue_choice = ""
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == "yes":
			car_scared.chase_target = greg
			car_scared.chase_closeness = 36
			car_scared.speed = 3600
			car_scared.chase(greg)
			car_scared.convo_progress = 0
			car_scared.default_lines.clear()
			car_scared.default_lines.append(&"car_scared_3")
		elif SOL.dialogue_choice == "oh":
			var tw := create_tween()
			tw.tween_property(car_scared, "global_position:x", -150, 3.0)
			car_scared.default_lines.clear()
			tw.tween_interval(2.0)
			tw.tween_callback(func():
				SOL.dialogue("car_scared_long_2")
				SOL.dialogue_closed.connect(func():
					_car_scared_run_over()
				, CONNECT_ONE_SHOT)
			)
	, CONNECT_ONE_SHOT)


func _car_run_over(pos: Vector2) -> void:
	SOL.vfx("overrun_down", pos, {"parent": self})
	SOL.vfx("explosion", pos,
			{"parent": self, "scale": Math.v2(0.5)})


func _destroy_fence() -> void:
	_car_run_over(fence_2.global_position)
	DAT.set_data(FENCE_DESTROYED, true)
	fence_2.queue_free()
	fence_inspect.key = "fence_carful"


func _car_scared_run_over() -> void:
	_car_run_over(car_scared.global_position)
	car_scared.set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(car_scared.get_node("Sprite2D"), "position", Vector2(10, 300), 1.0)
	tw.parallel().tween_property(
			car_scared.get_node("Sprite2D"), "rotation", TAU * 4, 2.0)
	car_scared.default_lines.clear()
	DAT.set_data(CAR_SCARED_DIED, true)
	tw.finished.connect(car_scared.queue_free)
