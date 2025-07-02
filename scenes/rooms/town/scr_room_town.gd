extends Room

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
	naturalist_setup()
	kid_setup()
	if DAT.get_data("trash_guy_inspected", false):
		$Houses/BlockNeighbours/Trashguy.queue_free()
	# disable thugs if bounty fulfilled
	if (DAT.get_data("fulfilled_bounty_thugs", false) and
			not DAT.get_data("hunks_enabled", false)):
		for i in thug_spawners:
			i.queue_free()
	if DAT.get_data("fulfilled_bounty_stray_animals", false):
		for i in animal_spawners:
			i.queue_free()


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
