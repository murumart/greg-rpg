extends Room

@onready var store_door := $Houses/Store/DoorArea
@onready var bike := $Houses/NeighbourHouse/Bike

@onready var thug_spawners := $Areas.find_children("ThugSpawner*")
@onready var animal_spawners := $Areas.find_children("AnimalSpawner*")


func _ready() -> void:
	super._ready()
	
	if DAT.get_data("stolen_from_store", 0) > 199 and\
	not DAT.get_data("fighting_cashier", false):
		store_door.destination = ""
	
	if not DAT.get_data("zerma_left", false):
		DAT.set_data("intro_cutscene_finished", true)
		DAT.set_data("zerma_left", true)
	
	neighbour_wife_position()
	tarikas_lines()
	pink_haired_girl_setup()
	naturalist_setup()
	if DAT.get_data("trash_guy_inspected", false):
		$Houses/BlockNeighbours/Trashguy.queue_free()
	if DAT.get_character("greg").level < 5: bike.queue_free()
	# disable thugs if bounty fulfilled
	if DAT.get_data("fulfilled_bounty_thugs", false) and\
	not DAT.get_data("hunks_enabled", false):
		for i in thug_spawners:
			i.queue_free()
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		for i in animal_spawners:
			i.queue_free()


func neighbour_wife_position() -> void:
	var neighbour_wife := $Houses/NeighbourHouse/NeighbourWife
	var time := wrapi(DAT.seconds, 0, DAT.NEIGHBOUR_WIFE_CYCLE)
	if time > (DAT.NEIGHBOUR_WIFE_CYCLE / 2.0):
		neighbour_wife.queue_free()


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
	var atgirl := $Houses/HousingBlock/Atgirl
	var time := wrapi(DAT.seconds, 0, DAT.ATGIRL_CYCLE)
	print("atgirl time: ", time)
	if time > DAT.ATGIRL_CYCLE / 4.0:
		atgirl.queue_free()
		DAT.set_data("has_interacted_with_atgirl", false)
		return

func _on_atgirl_inspected() -> void:
	var atgirl := $Houses/HousingBlock/Atgirl
	atgirl.default_lines.clear()
	var progress : int = DAT.get_data("atgirl_progress", 0)
	if not DAT.get_data("has_interacted_with_atgirl", false):
		DAT.set_data("has_interacted_with_atgirl", true)
		progress += (1 if SOL.dialogue_box.dialogues_dict.has("atgirl_%s" % str(progress + 1)) else 0)
		DAT.set_data("atgirl_progress", progress)
		atgirl.default_lines.append("atgirl_%s" % progress)
		return
	atgirl.default_lines.append("atgirl_%s" % progress)


func naturalist_setup() -> void:
	var left := $Other/NatureGuyLeft/NatureGuy
	if DAT.get_character("greg").get_defeated_character("grass") > 0:
		left.queue_free()


func _on_trash_guy_inspected() -> void:
	DAT.set_data("trash_guy_inspected", true)


