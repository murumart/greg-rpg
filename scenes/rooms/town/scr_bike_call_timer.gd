extends Timer

const BikeType = preload("res://scenes/decor/scr_bike.gd")

@onready var bike := $".." as BikeType
@onready var greg: PlayerOverworld = $"../../../../Greg"


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
	if DAT.get_data("bike_chasing", false) and\
	DAT.get_data("bike_ghosts_fought", []).size() < 1:
		await bike.ready
		bike_chase()
		return
	timeout.connect(func():
		if ResMan.get_character("greg").level >= 10 and\
		DAT.get_data("bike_ghosts_fought", []).size() < 1 and\
		not active and not chasing and\
		not is_close_enough() and DAT.player_capturers.is_empty():
			SOL.dialogue("phone_bike_ghost_call")
			SOL.dialogue_closed.connect(func(): active = true, CONNECT_ONE_SHOT)
		elif active and not is_close_enough():
			cycles += 1
			if cycles > 5 and cycles < 100:
				cycles = 300 # disable
				SOL.dialogue("phone_bike_ghost_call_ignore")
				SND.play_song("")
				DAT.set_data("bike_chasing", true)
				SOL.dialogue_closed.connect(func():
					bike_chase()
				, CONNECT_ONE_SHOT)
	)


func bike_chase() -> void:
	bike.global_position = greg.global_position
	bike.global_position.x -= 170 # off to the left
	chasing = true
	greg.saving_disabled = true
	active = false
	bike.interaction_area.queue_free()
	bike.collision.queue_free()


func _physics_process(delta: float) -> void:
	if not chasing or not DAT.player_capturers.is_empty():
		return
	var life_mult := ResMan.get_character("greg").health_perc()
	life_mult = remap(life_mult, 0.0, 1.0, 0.33, 1.0)
	var movex := signf(greg.global_position.x - bike.global_position.x)
	var movey := signf(greg.global_position.y - bike.global_position.y)
	#bike.global_position = bike.global_position.move_toward(
			#greg.global_position, delta * 67 * life_mult)
	bike.global_position += Vector2(movex, movey) * delta * 67 * life_mult
	#bike.global_position = bike.global_position.round()
	if distance() < 16:
		LTS.enter_battle(bike.alpha_battle_info)
		set_physics_process(false)
		DAT.set_data("bike_chasing", false)

