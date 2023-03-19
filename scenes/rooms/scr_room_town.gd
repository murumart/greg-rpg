extends Room

@onready var store_door := $Houses/Store/DoorArea


func _ready() -> void:
	super._ready()
	
	if DAT.get_data("stolen_from_store", 0) > 199:
		store_door.destination = ""
	
	neighbour_wife_position()
	tarikas_lines()
	pink_haired_girl_setup()
	if DAT.get_data("trash_guy_inspected", false):
		$Houses/BlockNeighbours/Trashguy.queue_free()


func neighbour_wife_position() -> void:
	var neighbour_wife := $Houses/NeighbourHouse/NeighbourWife
	var time := wrapi(DAT.seconds, 0, DAT.NEIGHBOUR_WIFE_CYCLE)
	if time > (DAT.NEIGHBOUR_WIFE_CYCLE / 2.0):
		neighbour_wife.position.x = -32767
		neighbour_wife.set_physics_process(false)
		neighbour_wife.hide()


func tarikas_lines() -> void:
	var tarikas : OverworldCharacter = $Other/BackPark/Tarikas
	var level := DAT.get_character("greg").level
	var lines_to_set : Array[StringName] = []
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


func pink_haired_girl_setup() -> void:
	var phg := $Houses/HousingBlock/PHG
	var time := wrapi(DAT.seconds, 0, DAT.PHG_CYCLE)
	if not time / 4 <= 300:
		phg.queue_free()
		DAT.set_data("has_interacted_with_phg", false)
		return

func _on_phg_inspected() -> void:
	var phg := $Houses/HousingBlock/PHG
	phg.default_lines.clear()
	var progress : int = DAT.get_data("phg_progress", 0)
	if not DAT.get_data("has_interacted_with_phg", false):
		DAT.set_data("has_interacted_with_phg", true)
		progress += 1 if SOL.dialogue_box.dialogues_dict.has("phg_%s" % str(progress + 1)) else 0
		DAT.set_data("phg_progress", progress)
		phg.default_lines.append("phg_%s" % progress)
		return
	phg.default_lines.append("phg_%s" % progress)
	


func _on_trash_guy_inspected() -> void:
	DAT.set_data("trash_guy_inspected", true)


