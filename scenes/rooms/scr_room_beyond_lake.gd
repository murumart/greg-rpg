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
		if not DAT.get_data("sun_spirit_engaged", false):
			tarikas.queue_free()
		else:
			$Greg.saving_disabled = false
			_remove_spirit()
			if DAT.get_data("tarikas_solar_done", false):
				tarikas.queue_free()
		if LTS.gate_id == &"exit_warstory":
			SOL.dialogue("tarikas_beyond_lake_3")
			DAT.set_data("tarikas_solar_done", true)
	else:
		_remove_spirit()
		tarikas.queue_free()
		$BronzeRifle.queue_free()

	if not Math.inrange(DAT.get_data("nr", 0.0), 0.090, 0.120):
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
	if tarikas.convo_progress >= 2:
		tarikas.default_lines.clear()


func _on_dialogue_closed() -> void:
	if DAT.get_data("show_anu_cutscene", false):
		DAT.set_data("show_anu_cutscene", false)
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
