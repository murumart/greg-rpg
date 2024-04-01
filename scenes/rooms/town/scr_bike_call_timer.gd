extends Timer

const BikeType = preload("res://scenes/decor/scr_bike.gd")

@onready var bike := $".." as BikeType
@onready var greg: PlayerOverworld = $"../../../../Greg"


var active := false
var cycles := 0
var chasing := false


func distance() -> float:
	return greg.global_position.distance_to(bike.global_position)


func is_close_enough() -> bool:
	return distance() < 160


func _ready() -> void:
	timeout.connect(func():
		if ResMan.get_character("greg").level >= 10 and\
		DAT.get_data("bike_ghosts_fought", []).size() < 1 and\
		not active and not chasing and\
		not is_close_enough():
			active = true
			SOL.dialogue("phone_bike_ghost_call")
		elif active and not is_close_enough():
			cycles += 1
			if cycles > 2 and cycles < 100:
				cycles = 300 # disable
				SOL.dialogue("phone_bike_ghost_call_ignore")
				SOL.dialogue_closed.connect(func():
					bike.global_position = greg.global_position
					bike.global_position.x -= 170 # off to the left
					chasing = true
					active = false
					bike.interaction_area.queue_free()
				, CONNECT_ONE_SHOT)
	)


func _physics_process(delta: float) -> void:
	if not chasing:
		return
	bike.global_position = bike.global_position.move_toward(
			greg.global_position, delta * 60)
	if distance() < 16:
		LTS.enter_battle(bike.alpha_battle_info)
		set_physics_process(false)

