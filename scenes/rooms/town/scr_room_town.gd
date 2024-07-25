extends Room

const STORE_CLEANUP_TIME_SECONDS := 400

@onready var store_door := $Houses/Store/DoorArea
@onready var bike := $Houses/UhhHouse/Bike

@onready var thug_spawners := $Areas.find_children("ThugSpawner*")
@onready var animal_spawners := $Areas.find_children("AnimalSpawner*")
@onready var vampire_cutscene: Node2D = $Other/CampfireSite/VampireCutscene


func _ready() -> void:
	super._ready()

	if not DAT.get_data("zerma_left", false):
		DAT.set_data("intro_cutscene_over", true)
		DAT.set_data("zerma_left", true)

	_store_door_setup()
	pink_haired_girl_setup()
	naturalist_setup()
	kid_setup()
	lake_hint_npc_setup()
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


func _store_door_setup() -> void:
	var current_cashier := StoreCashier.which_cashier_should_be_here()
	var stolen: int = DAT.get_data("stolen_from_store", 0)
	var cleanup_start_second: int = DAT.get_data("store_cleanup_started_second", -31399)
	prints(current_cashier, stolen)
	if (stolen > 199
			and not DAT.get_data("cashier_dead", false)
			and current_cashier == "nice"):
		store_door.destination = ""
	if (store_door.destination != ""
			and current_cashier == "absent"):
		store_door.destination = ""
		store_door.fail_dialogue = "store_cashier_absent"
	if (store_door.destination != ""
			and DAT.seconds - cleanup_start_second < STORE_CLEANUP_TIME_SECONDS):
		store_door.destination = ""
		store_door.fail_dialogue = "store_under_cleanup"


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
	if ResMan.get_character("greg").get_defeated_character("turf") > 6:
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


func lake_hint_npc_setup() -> void:
	var npc := $Houses/Store/LakeHintNpc as OverworldCharacter
	var time := DAT.seconds % DAT.LAKE_HINT_CYCLE as int
	var cyc := DAT.LAKE_HINT_CYCLE as int
	if not (Math.inrange(time, cyc * 0.33, cyc * 0.66)):
		npc.queue_free()
		DAT.set_data("lake_hint_received", false)
		return
	npc.inspected.connect(_on_lake_hint_received)
	var level := ResMan.get_character("greg").level
	if level >= 24 and not "lakeside" in DAT.get_data("visited_rooms", []):
		npc.default_lines.append("lake_hint")
		return
	npc.default_lines.append("lake_hint_" + str((randi() % 8) + 1))
	npc.default_lines.append("lake_hint_continue")

func _on_lake_hint_received(force_cutscene: bool = false) -> void:
	var cs := $Houses/Store/StoreCutscenePlayer as AnimationPlayer
	if not DAT.get_data("lake_hint_received", false):
		DAT.incri("store_ad_progress", 1)
	DAT.set_data("lake_hint_received", true)
	if force_cutscene or (DAT.get_data("store_ad_progress", 0) >= 3 and
			not DAT.get_data("saw_ad_cutscene", false)):
		DAT.set_data("saw_ad_cutscene", true)
		DAT.capture_player("cutscene")
		cs.play("cutscene_start")
		cs.animation_finished.connect(func(_a):
			SOL.dialogue("lake_hint_cutscene_1")
			SOL.dialogue_closed.connect(func():
				cs.play("cutscene_end")
				DAT.free_player("cutscene")
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)


