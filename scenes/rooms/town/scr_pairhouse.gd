extends Node2D

const TURF_NEEDED_TO_DIE := 30

var int_disabled := false

@onready var guy: OverworldCharacter = $Guy
@onready var door: Area2D = $DoorArea2


func _ready() -> void:
	pairhouse_guy_setup()


func pairhouse_guy_setup() -> void:
	if DAT.get_data("turf_mission_fulfilled", false):
		door.destination = "super_gaming_house"
	if ((not DAT.get_data("fulfilled_bounty_stray_animals", false))
			or DAT.get_data("turf_mission_fulfilled", false)
			or DAT.get_data("expressed_jooky_concern", false)):
		guy.queue_free()
		return
	guy.inspected.connect(_on_ph_guy_inspected)


func _on_ph_guy_inspected() -> void:
	guy.default_lines.clear()
	if int_disabled:
		return
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		guy.default_lines = ["ph_guy_jooky_missing_1", "ph_guy_jooky_missing_2"]
		DAT.set_data("expressed_jooky_concern", true)
		return
	if not DAT.get_data("turf_mission_active", false):
		guy.default_lines = ["ph_guy_hello"]
		DAT.set_data("turf_mission_active", true)
		DAT.set_data("mission_start_turf_killed",
			ResMan.get_character("greg").get_defeated_character("turf"))
		return
	var turf_killed: int = (
			ResMan.get_character("greg").get_defeated_character("turf")
			- DAT.get_data("mission_start_turf_killed", 0))
	if turf_killed >= TURF_NEEDED_TO_DIE:
		int_disabled = true
		guy.default_lines = ["ph_guy_turfwin"]
		DAT.set_data("turf_mission_fulfilled", true)
		DAT.set_data("turf_mission_active", false)
		door.destination = "super_gaming_house"
		SOL.dialogue_closed.connect(
			func():
				var tw := create_tween()
				tw.tween_property(guy, "modulate:a", 0.0, 1.0)
				tw.tween_callback(guy.queue_free)
		, CONNECT_ONE_SHOT)
		return
	SOL.dialogue_box.dial_concat("ph_guy_checkup", 1, [turf_killed, TURF_NEEDED_TO_DIE])
	guy.default_lines = ["ph_guy_checkup"]
