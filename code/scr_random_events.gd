extends Node2D

@onready var greg: PlayerOverworld = get_parent()
@onready var event_timer: Timer = $EventTimer


func _timer_tick() -> void:
	if not greg.state == greg.States.FREE_MOVE:
		return
	var nr: float = DAT.get_data("nr", 0.0)
	
	if randf() < 0.0000012:
		SOL.vfx("to_be_continue")
	elif (randf() < 0.002 and Math.inrange(nr, 0.35, 0.69)
			and not DAT.get_data("strange_calle_received", false)):
		SOL.dialogue("hpone_zerma")
		DAT.set_data("strange_calle_received", true)
