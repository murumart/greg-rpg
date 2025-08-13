extends Room

@onready var spirit := $Areas/SunSpirit
@onready var tarikas := $Building/StatueBase/Tarikas
@onready var fisher_ghost := $Areas/BikeGhostFishing
@onready var second_sun_spirit_encounter: Area2D = $Areas/SecondSunSpiritEncounter
@onready var greg: PlayerOverworld = $Greg
@onready var wherepos: Node2D = $Areas/SecondSunSpiritEncounter/Wherepos
@onready var third_sun_spirit_encounter: Area2D = $Areas/ThirdSunSpiritEncounter


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(_on_dialogue_closed)
	second_sun_spirit_encounter.body_entered.connect(_second_sunspirit_test)
	third_sun_spirit_encounter.body_entered.connect(_third_sunspirit_test)
	if not DAT.get_data("sunset_triggered", false):
		$Areas/FishScaredSunHint.queue_free()
		if DAT.get_data("sun_spirit_engaged", false):
			_remove_spirit()
			$Greg.saving_disabled = false
		else:
			tarikas.queue_free()
	else:
		_remove_spirit()
		tarikas.queue_free()
		$BronzeRifle.queue_free()
	if not DAT.get_data("nr", 0.0) < 0.1:
		fisher_ghost.queue_free()
	if DAT.get_data("sun_spirit_engagement_position", false):
		$OverworldTiles/BurnMark.global_position = (
				DAT.get_data("sun_spirit_engagement_position") - Vector2(0, 16))


func _on_sun_spirit_inspected() -> void:
	$Areas/SunSpirit/AmbientLoop.playing = false
	spirit.random_movement = true
	DAT.set_data("sun_spirit_engaged", true)
	DAT.set_data("sun_spirit_engagement_position", $Greg.global_position)


func _on_tarikas_inspected() -> void:
	DAT.set_data("met_tarikas_beyond_lake", true)
	if tarikas.convo_progress >= 3:
		tarikas.default_lines.clear()
		if DAT.get_data("dont_care_about_tarikas_story", false):
			SOL.dialogue("tarikas_beyond_lake_bother")
		elif DAT.get_data("heard_tarikas_story", false):
			SOL.dialogue("tarikas_beyond_lake_again")
		elif DAT.get_data("you_know_of_anu", false):
			SOL.dialogue("tarikas_beyond_lake_offerstory")
		elif not DAT.get_data("heard_tarikas_story", false):
			SOL.dialogue("tarikas_beyond_lake_4")
		else:
			SOL.dialogue("tarikas_beyond_lake_again")


func _on_dialogue_closed() -> void:
	if SOL.dialogue_choice == "yes!!":
		SOL.dialogue_choice = ""
		DAT.set_data("heard_tarikas_story", true)
		LTS.level_transition("res://scenes/cutscene/scn_warstory.tscn")
	elif SOL.dialogue_choice in ["power", "souls", "desire", "human", "inhuman"]:
		DAT.set_data("spirit_definition", SOL.dialogue_choice)
		DIR.sej(14, SOL.dialogue_choice)
		SOL.dialogue_choice = ""


func _second_sunspirit_test(body: Node2D) -> void:
	if body == greg:
		spirit.global_position = wherepos.global_position
		spirit.chase_target = null
		spirit.default_lines.clear()
		spirit.default_lines.append("sun_spirit_walk_past")


func _third_sunspirit_test(body: Node2D) -> void:
	if body == greg:
		spirit.chase_target = greg
		spirit.chase(greg)


func _remove_spirit() -> void:
	spirit.queue_free()
	second_sun_spirit_encounter.queue_free()
	third_sun_spirit_encounter.queue_free()
