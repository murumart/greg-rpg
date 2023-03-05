extends Room

@onready var store_door := $Houses/Store/DoorArea


func _ready() -> void:
	super._ready()
	
	if DAT.get_data("stolen_from_store", 0) > 199:
		store_door.destination = ""
	
	neighbour_wife_position()
	tarikas_lines()


func neighbour_wife_position() -> void:
	var neighbour_wife := $Houses/NeighbourHouse/NeighbourWife
	var time := wrapi(DAT.seconds, 0, DAT.NEIGHBOUR_WIFE_CYCLE)
	if time > DAT.NEIGHBOUR_WIFE_CYCLE / 2:
		neighbour_wife.position.x = -32767
		neighbour_wife.set_physics_process(false)
		neighbour_wife.hide()


func tarikas_lines() -> void:
	var tarikas : OverworldCharacter = $Other/BackPark/Tarikas
	var level := DAT.get_character("greg").level
	var lines_to_set : Array[StringName]
	tarikas.convo_progress = 0
	if not DAT.get_data("tarikas_talked_to", false):
		lines_to_set.append("tarikas_hello")
	if level < 5:
		pass
	elif Math.inrange(level, 6, 10):
		lines_to_set.append("tarikas_10")
	elif Math.inrange(level, 11, 15):
		lines_to_set.append("tarikas_15")
	elif Math.inrange(level, 16, 25):
		if DAT.get_data("biking_games_finished", 0) > 0:
			lines_to_set.append("tarikas_25")
	lines_to_set.append("tarikas_finish")
	tarikas.default_lines = lines_to_set

func _on_tarikas_inspected() -> void:
	tarikas_lines()
	DAT.set_data("tarikas_talked_to", true)

