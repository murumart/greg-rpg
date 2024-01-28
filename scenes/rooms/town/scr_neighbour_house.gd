extends Node2D

const NEIGHBOUR_WIFE_CYCLE := 470
const GreenhouseType := preload("res://scenes/decor/scr_greenhouse.gd")

@onready var neighbour_wife := $NeighbourWife as OverworldCharacter
@onready var greenhouse := $NeighboursGreenhouse as GreenhouseType


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


func neighbour_wife_position() -> void:
	var time := wrapi(DAT.seconds, 0, NEIGHBOUR_WIFE_CYCLE)
	if time > (NEIGHBOUR_WIFE_CYCLE / 2.0) and LTS.gate_id != &"house-town":
		neighbour_wife.queue_free()
