extends Node2D

const CAR_SCARED_DIED := &"car_scared_died"

const NEIGHBOUR_WIFE_CYCLE := 470
const GreenhouseType := preload("res://scenes/decor/scr_greenhouse.gd")

@onready var neighbour_wife := $NeighbourWife as OverworldCharacter
@onready var greenhouse := $NeighboursGreenhouse as GreenhouseType
@onready var car_scared := $CarScared as OverworldCharacter
@onready var greg := $"../../Greg" as PlayerOverworld


func _ready() -> void:
	neighbour_wife_position()
	neighbour_wife.inspected.connect(func():
		var time_diff := DAT.seconds - DAT.get_data(
				greenhouse.get_save_key("vegs_eaten_second"), -123812391) as int
		if time_diff <= 15:
			neighbour_wife.convo_progress = 0
			neighbour_wife.default_lines.clear()
			neighbour_wife.default_lines.append("neighbour_wife_ate_greenhouse")
			neighbour_wife.default_lines.append("neighbour_wife_ate_greenhouse_2")
			neighbour_wife.inspected.disconnect(neighbour_wife.inspected.get_connections()[0]["callable"])
	)
	car_scared.inspected.connect(car_scared_inspected)
	if DAT.get_data(CAR_SCARED_DIED, false):
		car_scared.queue_free()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(car_scared):
		return
	if car_scared.global_position.x > -56 and car_scared.is_physics_processing():
		SOL.vfx("overrun_down", car_scared.global_position, {"parent": car_scared})
		SOL.vfx("explosion", car_scared.global_position, {
				"parent": car_scared, "scale": Math.v2(0.5)})
		car_scared.set_physics_process(false)
		car_scared.get_node("Sprite2D").rotation_degrees = 90
		car_scared.get_node("Sprite2D").position.y = 0
		car_scared.default_lines.clear()
		car_scared.convo_progress = 0
		car_scared.default_lines.append_array(["car_scared_3", "car_scared_4"])
		DAT.set_data(CAR_SCARED_DIED, true)


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
	, CONNECT_ONE_SHOT)


func _on_car_scared_visible_screen_exited() -> void:
	car_scared.queue_free()
