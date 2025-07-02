extends Timer

const BikeType = preload("res://scenes/decor/scr_bike.gd")

@onready var bike := get_parent() as BikeType
@export var greg: PlayerOverworld


var active := false:
	set(to):
		DAT.set_data("bike_call_timer_active", to)
	get:
		return DAT.get_data("bike_call_timer_active", false)
var cycles := 0
var chasing := false


func distance() -> float:
	return greg.global_position.distance_to(bike.global_position)


func is_close_enough() -> bool:
	return distance() < 160


func _ready() -> void:
	if ResMan.get_character("greg").level < 5:
		bike.queue_free()
		return
	if not DAT.get_data("bike_ghosts_fought", []).is_empty():
		queue_free()
		return
	timeout.connect(func():
		if (Math.inrange(ResMan.get_character("greg").level, 11, 20)
			and DAT.get_data("bike_ghosts_fought", []).is_empty()
			and not active
			and not chasing
			and not is_close_enough()
			and DAT.player_capturers.is_empty()
		):
			SOL.dialogue("phone_bike_ghost_call")
			SOL.dialogue_closed.connect(func(): active = true, CONNECT_ONE_SHOT)
		elif (active
			and not is_close_enough()
			and DAT.player_capturers.is_empty()
		):
			cycles += 1
	)
