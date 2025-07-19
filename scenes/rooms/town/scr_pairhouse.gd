extends Node2D

const TURF_NEEDED_TO_DIE := 30

var int_disabled := false

@onready var guy: OverworldCharacter = $Guy
@onready var door: Area2D = $DoorArea2

@onready var bald_man := $MailInfo as OverworldCharacter



func _ready() -> void:
	pairhouse_guy_setup()
	_bald_man_setup()


func pairhouse_guy_setup() -> void:
	if DAT.get_data("turf_mission_fulfilled", false):
		door.destination = "super_gaming_house"
	if ((DAT.get_data("fulfilled_bounty_stray_animals", false))
			or DAT.get_data("turf_mission_fulfilled", false)
			or DAT.get_data("expressed_jooky_concern", false)):
		guy.queue_free()
		return
	guy.inspected.connect(_on_ph_guy_inspected)


func _bald_man_setup() -> void:
	if DAT.get_data("heard_mail_info_played", false):
		bald_man.default_lines.append("bald_man_default")
	elif DAT.get_data("biking_games_finished", 0) and DAT.get_data("heard_mail_info", false):
		bald_man.default_lines.clear()
		bald_man.default_lines.append("mail_game_info_played")
		bald_man.inspected.connect(func():
			SOL.dialogue_closed.connect(func():
				bald_man.default_lines.clear()
				SND.play_sound(preload("res://sounds/flee.ogg"))
				var tw := create_tween()
				tw.tween_property(bald_man, "modulate:a", 0.0, 1.0)
				tw.tween_callback(bald_man.queue_free)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	elif DAT.get_data("biking_games_finished", 0) > 0:
		bald_man.default_lines.append("bald_man_default")
	elif Time.get_datetime_dict_from_system().month == 6:
		bald_man.default_lines.push_front("mail_game_pride_month")


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
