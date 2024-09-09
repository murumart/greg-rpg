extends Room

@onready var bike := $Houses/UhhHouse/Bike

@onready var thug_spawners := $Areas.find_children("ThugSpawner*")
@onready var animal_spawners := $Areas.find_children("AnimalSpawner*")
@onready var vampire_cutscene: Node2D = $Other/CampfireSite/VampireCutscene
@onready var store: Node2D = $Houses/Store


func _ready() -> void:
	super._ready()

	if not DAT.get_data("zerma_left", false):
		DAT.set_data("intro_cutscene_over", true)
		DAT.set_data("zerma_left", true)

	store.setup()
	pink_haired_girl_setup()
	naturalist_setup()
	kid_setup()
	if DAT.get_data("trash_guy_inspected", false):
		$Houses/BlockNeighbours/Trashguy.queue_free()
	if ResMan.get_character("greg").level < 9:
		bike.queue_free()
	# disable thugs if bounty fulfilled
	if (DAT.get_data("fulfilled_bounty_thugs", false) and
			not DAT.get_data("hunks_enabled", false)):
		for i in thug_spawners:
			i.queue_free()
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		for i in animal_spawners:
			i.queue_free()
	if Math.inrange(DAT.get_data("nr"), 0.5, 0.6):
		if not DAT.get_data("saw_cool_bird_message", false):
			$Other/BirdBlocker/InspectArea.key = "blocking_bird_2"
			$Other/BirdBlocker/InspectArea.inspected.connect(
				func():
					DAT.set_data("saw_cool_bird_message", true)
					await get_tree().process_frame
					$Other/BirdBlocker/InspectArea.key = "blocking_bird"
			)


func pink_haired_girl_setup() -> void:
	var atgirl := $Houses/HousingBlock/Atgirl
	var time := DAT.seconds % DAT.ATGIRL_CYCLE
	var progress: int = DAT.get_data("atgirl_progress", 1)
	atgirl.default_lines.append("atgirl_" + str(progress))
	if time > DAT.ATGIRL_CYCLE * 0.25: # first quarter she's in town
		atgirl.queue_free()
		# updating progress when leaving, when has been interacted with
		if DAT.get_data("has_interacted_with_atgirl", false):
			if SOL.dialogue_exists("atgirl_" + str(progress + 1)):
				progress += 1
		DAT.set_data("has_interacted_with_atgirl", false)
		DAT.set_data("atgirl_progress", progress)
		return

func _on_atgirl_inspected() -> void:
	var atgirl := $Houses/HousingBlock/Atgirl as OverworldCharacter
	var progress: int = DAT.get_data("atgirl_progress", 1)
	if not DAT.get_data("has_interacted_with_atgirl", false):
		DAT.set_data("has_interacted_with_atgirl", true)
		if progress == 9:
			progress += 1
			atgirl.default_lines.clear()
			DAT.set_data("atgirl_progress", progress)


func naturalist_setup() -> void:
	var left := $Other/NatureGuyLeft/NatureGuy
	if ResMan.get_character("greg").get_defeated_character("turf") > 24:
		left.queue_free()


func kid_setup() -> void:
	var first_encounter := $Houses/NeighbourHouse/KidEncounter as OverworldCharacter
	if not $Other/CampfireSite/Campfire.lit:
		$Other/CampfireSite/CampsiteKid.queue_free()
	if DAT.get_data("kid_encountered", false):
		first_encounter.queue_free()
		return
	first_encounter.inspected.connect(kid_first_encounter, CONNECT_ONE_SHOT)

func kid_first_encounter() -> void:
	var first_encounter := $Houses/NeighbourHouse/KidEncounter as OverworldCharacter
	DAT.set_data("kid_encountered", true)
	SOL.dialogue_closed.connect(func():
		first_encounter.set_collision_layer_value(4, false)
		first_encounter.default_lines.clear()
		var tw := create_tween()
		tw.tween_property(first_encounter, "global_position:y", 400, 1.0)
		tw.tween_callback(first_encounter.queue_free)
	, CONNECT_ONE_SHOT)


func _on_trash_guy_inspected() -> void:
	DAT.set_data("trash_guy_inspected", true)
