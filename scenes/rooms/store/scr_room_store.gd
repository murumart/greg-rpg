extends Room

# the store room scene
# copied over from old greg and adjusted


# item types stored here
const HEALING_ITEMS := ["medkit", "plaster", "pills", "cough_syrup"]
const COLD_HEALING := ["ice_pack"]
const FOOD_ITEMS := ["muesli", "mueslibar", "bread", "salt"]
const COLD_FOOD := ["frozen_meat"]
const BUILDING_ITEMS := ["tape", "glue"]
const COLD_BUILDING := ["antifreeze"]

const WAIT_UNTIL_RESTOCK := 300
const WAIT_UNTIL_CASHIER_SWITCH := 420

var item_storage := []

@onready var shelves := $Shelves.get_children()
# this is a dictionary containing a huge list of all shelves in the store
# which are stored as dictionaries that store the item type and count and such
var store_data := {}

var store_cashier := StoreCashier.new()

var wet_slop := false

@onready var ui := $StoreUi
@onready var shopping_list := $StoreUi/ShoppingList

@onready var cashier_sprite := $Kassa/Cashier/Sprite
@onready var cashier := $Kassa/Cashier as OverworldCharacter
@onready var decor := $Decor


func _ready():
	super._ready()
	store_cashier.finished.connect(_on_kassa_finished)
	store_cashier.dothething.connect(dothethingthething)
	remove_child(ui)
	SOL.add_ui_child(ui, -1)
	set_store_wall_colours()

	for s in shelves:
		s.item_taken.connect(_on_item_taken)

	update_shopping_list()
	load_store_data()
	decor.store_cashier = store_cashier
	if not store_cashier.cashier == "dead":
		SND.play_song("air_conditioning", 1.0, {
			play_from_beginning = true,
			start_volume = 0,
		})
	decor.neighbour_wife_position()
	decor.product_placement()
	if LTS.gate_id == &"exit_cashier_fight":
		DAT.free_player("cashier_revenge")
		decor.exit_cashier_fight()
	if DAT.get_data("you_gotta_see_the_water_drain", false):
		DAT.set_data("you_gotta_see_the_water_drain", false)
		wet_slop = true
		for s in shelves:
			s.is_wet = true


func set_store_wall_colours():
	var store_wall := $InteriorTiles as TileMap
	print(Math.süsarv())
	var mn = Math.süsarv()
	var color = Color(mn, 0.5, 0.8 - mn * 0.5).lightened(0.2)

	store_wall.set_layer_modulate(1, color)


func _on_item_taken(ittype: String):
	if ittype in ResMan.items:
		DAT.appenda("unpaid_items", ittype)
	update_shopping_list()


func load_store_data():
	store_data = DAT.get_data("store_data", {})
	check_restock()
	check_cashier_switch()
	if store_data.is_empty():
		restock()
	for s in store_data.get("shelves", []).size():
		var shelf = store_data.get("shelves")[s]
		shelves[s].inventory = shelf["inventory"]
		shelves[s].set_type(shelf["type"])


# put items on the shelves
func restock() -> void:
	# if the cashier has been fought and won against, don't
	if DAT.get_data("cashier_dead", false):
		DAT.set_data("noticed_cashier_gone", DAT.seconds)
		return
	var store_shelf_count := shelves.size()
	var cold_shelves := []
	for x in store_shelf_count:
		if shelves[x].cold:
			cold_shelves.append(x)
	var arrays := [HEALING_ITEMS, FOOD_ITEMS, BUILDING_ITEMS]
	var cold_arrays := [COLD_HEALING, COLD_FOOD, COLD_BUILDING]

	store_data["shelves"] = []
	for i in store_shelf_count:
		var inventory = []
		var type := randi() % 3
		var cold := i in cold_shelves
		var from: Array = arrays[type] if not cold else cold_arrays[type]
		var fromremove := from.duplicate()
		for J in randi() % 4:
			if fromremove.size() < 1: continue
			var item = fromremove.pick_random()
			if item not in ResMan.items.keys(): continue
			fromremove.erase(item)
			var itemprice = ResMan.get_item(item).price
			var itemcount = roundi(minf(3000 / pow(itemprice, 1.5) + 1, 8)) # ???
			if itemcount < 1: continue
			inventory.append({"item": item,"count": itemcount})
		var itemtype := type + 1
		if inventory.size() < 1:
			itemtype = 0
		store_data["shelves"].append({"inventory": inventory, "type": itemtype})
	DAT.set_data("store_data", store_data)
	DAT.set_data("store_restock_second", DAT.seconds)


func _save_me():
	store_data["shelves"].clear()
	for s in shelves.size():
		store_data["shelves"].append(
				{
					"inventory": shelves[s].inventory,
					"type": shelves[s].type
				}
			)
	for x in DAT.get_data("store_data", {}).keys():
		if x in store_data:
			DAT.A["store_data"][x] = store_data[x]


func check_restock() -> void:
	if DAT.seconds - DAT.get_data("store_restock_second", -30000000) >= WAIT_UNTIL_RESTOCK:
		restock()


func check_cashier_switch() -> void:
	# oops....
	if DAT.get_data("cashier_dead", false):
		cashier.queue_free()
		store_cashier.cashier = "dead" # happens
		DIR.sej(144, 1)
		return
	# load the current cashier based on their schedule
	if not DAT.get_data("cashier_mean_defeated") and \
			(wrapi(DAT.seconds, 0, WAIT_UNTIL_CASHIER_SWITCH * 2) > WAIT_UNTIL_CASHIER_SWITCH or \
			LTS.gate_id == &"exit_cashier_fight"):
		store_cashier.cashier = "mean"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_mean.tres")
	else:
		store_cashier.cashier = "nice"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_nice.tres")


func _on_kassa_speak_on_interact() -> void:
	if wet_slop:
		SOL.dialogue("cashier_%s_after_president_fight" % store_cashier.cashier)
		return
	store_cashier.speak()
	if not is_instance_valid(cashier):
		return
	cashier.move_to(cashier.global_position)
	cashier.direct_walking_animation(Vector2.RIGHT)
	cashier.set_state(OverworldCharacter.States.TALKING)


func _on_kassa_finished() -> void:
	update_shopping_list()


# display shopping cart items in the top right of the screen
func update_shopping_list() -> void:
	var unpaid_items: Array = DAT.get_data("unpaid_items", [])
	var temp_dict := {}
	var total := 0
	for i in unpaid_items:
		if i in temp_dict:
			temp_dict[i] += 1
		else:
			temp_dict[i] = 1
	var text := "[right]"
	for i in temp_dict:
		text += "%s x %s\n" % [ResMan.get_item(i).name, temp_dict[i]]
		total += ResMan.get_item(i).price * temp_dict[i]
	text += "total: " + str(total)
	shopping_list.text = text


# final warning. unless you go back and run into the area again
func _on_stealing_area_entered(_body: Node2D) -> void:
	store_cashier.warn()


func _on_room_gate_entered() -> void:
	var stolen_profit := 0
	for i in DAT.get_data("unpaid_items", []):
		stolen_profit += ResMan.get_item(i).price
	DAT.incri("%s_profit_stolen" % store_cashier.cashier, stolen_profit)
	if wet_slop:
		DAT.set_data("store_cleanup_started_second", DAT.seconds)


# mean cashier steal cutscene
func dothethingthething() -> void:
	decor.dothethingthething()


