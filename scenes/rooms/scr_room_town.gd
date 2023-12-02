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
	pink_haired_girl_setup()
	naturalist_setup()
	pairhouse_guy_setup()
	skatepark_setup()
	kid_setup()
	if DAT.get_data("trash_guy_inspected", false):
		$Houses/BlockNeighbours/Trashguy.queue_free()
	if DAT.get_character("greg").level < 9: bike.queue_free()
	# disable thugs if bounty fulfilled
	if (DAT.get_data("fulfilled_bounty_thugs", false) and
	not DAT.get_data("hunks_enabled", false)):
		for i in thug_spawners:
			i.queue_free()
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		for i in animal_spawners:
			i.queue_free()
	if not $Other/CampfireSite/Campfire.lit:
		$Other/CampfireSite/CampsiteKid.queue_free()


func neighbour_wife_position() -> void:
	var neighbour_wife := $Houses/NeighbourHouse/NeighbourWife
	var time := wrapi(DAT.seconds, 0, DAT.NEIGHBOUR_WIFE_CYCLE)
	if time > (DAT.NEIGHBOUR_WIFE_CYCLE / 2.0) and LTS.gate_id != &"house-town":
		neighbour_wife.queue_free()


func pink_haired_girl_setup() -> void:
	var atgirl := $Houses/HousingBlock/Atgirl
	var time := wrapi(DAT.seconds, 0, DAT.ATGIRL_CYCLE)
	if time > DAT.ATGIRL_CYCLE / 4.0:
		atgirl.queue_free()
		DAT.set_data("has_interacted_with_atgirl", false)
		return

func _on_atgirl_inspected() -> void:
	var atgirl := $Houses/HousingBlock/Atgirl
	var progress : int = DAT.get_data("atgirl_progress", 1)
	if not DAT.get_data("has_interacted_with_atgirl", false):
		atgirl.default_lines.clear()
		DAT.set_data("has_interacted_with_atgirl", true)
		atgirl.default_lines.append("atgirl_%s" % progress)
		progress += (1 if SOL.dialogue_box.dialogues_dict.has("atgirl_%s" %
			str(progress + 1)) else 0)
		DAT.set_data("atgirl_progress", progress)


func naturalist_setup() -> void:
	var left := $Other/NatureGuyLeft/NatureGuy
	if DAT.get_character("greg").get_defeated_character("turf") > 0:
		left.queue_free()


func pairhouse_guy_setup() -> void:
	var guy := $Houses/Pairhouse/Guy as OverworldCharacter
	var door := $Houses/Pairhouse/DoorArea2
	if DAT.get_data("turf_mission_fulfilled", false):
		door.destination = "super_gaming_house"
	if ((DAT.seconds < DAT.PH_GUY_WAIT and not
			DAT.get_data("fulfilled_bounty_stray_animals", false)) or 
		DAT.get_data("turf_mission_fulfilled", false) or
		DAT.get_data("expressed_jooky_concern", false)):
		guy.queue_free()
		return
	guy.inspected.connect(_on_ph_guy_inspected)

var int_disabled := false
func _on_ph_guy_inspected() -> void:
	var guy := $Houses/Pairhouse/Guy as OverworldCharacter
	var door := $Houses/Pairhouse/DoorArea2
	guy.default_lines.clear()
	if int_disabled: return
	var turf_killed : int = (DAT.get_character("greg").get_defeated_character(
		"turf") - DAT.get_data("mission_start_turf_killed", 0))
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		guy.default_lines = ["ph_guy_jooky_missing_1", "ph_guy_jooky_missing_2"]
		DAT.set_data("expressed_jooky_concern", true)
		return
	if not DAT.get_data("turf_mission_active", false):
		guy.default_lines = ["ph_guy_hello"]
		DAT.set_data("turf_mission_active", true)
		DAT.set_data("mission_start_turf_killed",
			DAT.get_character("greg").get_defeated_character("turf"))
		return
	if turf_killed >= 30:
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
	SOL.dialogue_box.dial_concat("ph_guy_checkup", 1, [turf_killed])
	guy.default_lines = ["ph_guy_checkup"]


func skatepark_setup() -> void:
	var skate_worry := $Houses/Skatepark/SkateWorry as OverworldCharacter
	if not DAT.get_data("fulfilled_bounty_thugs", false) or \
	DAT.get_data("hunks_enabled", false):
		$Houses/Skatepark/Goodness.queue_free()
		return
	skate_worry.default_lines.clear()
	if DAT.get_data("hunks_enabled", false):
		skate_worry.default_lines = ["skate_worry_bad", "skate_worry_3"]
	else:
		skate_worry.default_lines = ["skate_worry_good", "skate_worry_3"]


func kid_setup() -> void:
	var first_encounter := $Houses/NeighbourHouse/KidEncounter as OverworldCharacter
	first_encounter.inspected.connect(kid_first_encounter, CONNECT_ONE_SHOT)
	if DAT.get_data("kid_encountered", false):
		first_encounter.queue_free()

func kid_first_encounter() -> void:
	var first_encounter := $Houses/NeighbourHouse/KidEncounter as OverworldCharacter
	print("yp")
	DAT.set_data("kid_encountered", true)
	SOL.dialogue_closed.connect(func():
		first_encounter.set_collision_layer_value(4, false)
		var tw := create_tween()
		tw.tween_property(first_encounter, "global_position:y", 400, 1.0)
		tw.tween_callback(first_encounter.queue_free)
	, CONNECT_ONE_SHOT)


func _on_trash_guy_inspected() -> void:
	DAT.set_data("trash_guy_inspected", true)


