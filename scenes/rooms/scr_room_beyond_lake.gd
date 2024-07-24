extends Room

@onready var spirit := $Areas/SunSpirit
@onready var tarikas := $Building/StatueBase/Tarikas
@onready var fisher_ghost := $Areas/BikeGhostFishing


func _ready() -> void:
	super._ready()
	SOL.dialogue_closed.connect(_on_dialogue_closed)
	if DAT.get_data("sun_spirit_engaged", false):
		spirit.queue_free()
		$Greg.saving_disabled = false
	else: tarikas.queue_free()
	if not DAT.get_data("nr", 0.0) < 0.1:
		fisher_ghost.queue_free()
	if DAT.get_data("sun_spirit_engagement_position", false):
		$OverworldTiles/BurnMark.global_position = (
				DAT.get_data("sun_spirit_engagement_position") - Vector2(0, 16))


func _on_sun_spirit_inspected() -> void:
	$Areas/SunSpirit/AmbientLoop.playing = false
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





