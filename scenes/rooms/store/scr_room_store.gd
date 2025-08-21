extends Room

# the store room scene
# copied over from old greg and adjusted

const ShelfType := preload("res://scenes/decor/scr_store_shelf.gd")

# item types stored here
const HEALING_ITEMS := ["medkit", "plaster", "pills", "cough_syrup"]
const COLD_HEALING := ["ice_pack"]
const FOOD_ITEMS := ["muesli", "mueslibar", "bread", "salt", "cracker_fire"]
const COLD_FOOD := ["frozen_meat", "ice_cream"]
const BUILDING_ITEMS := ["tape", "glue", "fire_cracker"]
const COLD_BUILDING := ["antifreeze"]

const WAIT_UNTIL_RESTOCK := 300
const WAIT_UNTIL_CASHIER_SWITCH := 420

var item_storage := []

@onready var shelves := $Shelves.get_children()
# this is a dictionary containing a huge list of all shelves in the store
# which are stored as dictionaries that store the item type and count and such
var store_data := {}

var store_cashier := StoreCashier.new()
var unpaid_items: Array:
	get: return DAT.get_data("unpaid_items", [])
	set(to): DAT.set_data("unpaid_items", to)

var wet_slop := false

@onready var ui := $StoreUi
@onready var shopping_list := $StoreUi/ShoppingList

@onready var cashier_sprite := $Kassa/Cashier/Sprite
@onready var cashier := $Kassa/Cashier as OverworldCharacter
@onready var decor := $Decor
@onready var mail_man_check_timer: Timer = $Decor/MailMan/MailManCheckTimer
@onready var mail_man: OverworldCharacter = $Decor/MailMan
@onready var restroom_door_area := %RestroomDoor/DoorArea


func _ready():
	super._ready()
	if not unpaid_items:
		unpaid_items = []
	store_cashier.finished.connect(_on_kassa_finished)
	store_cashier.dothething.connect(dothethingthething)
	restroom_door_area.knocked.connect(_restroom_door_knocked)
	remove_child(ui)
	SOL.add_ui_child(ui, -1)
	set_store_wall_colours()
	mail_man_check_timer.timeout.connect(_mail_man_check)
	if not is_mail_man_here():
		mail_man.queue_free()

	for s in shelves:
		s.item_taken.connect(_on_item_taken)

	update_shopping_list()
	load_store_data()
	decor.store_cashier = store_cashier
	if not store_cashier.cashier == "dead":
		SND.play_song("air_conditioning", 1.0, {
			play_from_beginning = LTS.gate_id != &"store-restroom",
			start_volume = 0,
		})
	decor.neighbour_wife_position()
	decor.product_placement()
	if LTS.gate_id == &"exit_cashier_fight":
		DAT.free_player("cashier_revenge")
		decor.exit_cashier_fight()
	if DAT.get_data("you_gotta_see_the_water_drain", false):
		restroom_door_area.set_collision_layer_value(3, false)
		DAT.set_data("you_gotta_see_the_water_drain", false)
		if is_instance_valid(decor.funny_area):
			decor.funny_area.queue_free()
		wet_slop = true
		for s in shelves:
			s.is_wet = true


func set_store_wall_colours():
	var store_wall := $InteriorTiles/Layer1 as TileMapLayer
	var mn := Math.süsarv()
	var color := Color(mn, 0.5, 0.8 - mn * 0.5).lightened(0.2)
	store_wall.modulate = color


func _on_item_taken(ittype: String):
	if ittype in ResMan.items:
		unpaid_items.append(ittype)
	update_shopping_list()


func load_store_data():
	store_data = DAT.get_data("store_data", {})
	check_restock()
	check_cashier_switch()
	if store_data.is_empty():
		restock()
	for s in store_data.get("shelves", []).size():
		var shelf: Dictionary = store_data.get("shelves")[s]
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
	var food := FOOD_ITEMS
	if is_mail_man_here():
		food = Math.reaap(FOOD_ITEMS.duplicate(), "red_sauce")
	var arrays := [HEALING_ITEMS, food, BUILDING_ITEMS]
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
	var which := StoreCashier.which_cashier_should_be_here()
	store_cashier.cashier = which
	if which == "dead" or which == "absent":
		cashier.queue_free()
		return
	# load the current cashier based on their schedule
	if which == "mean":
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_mean.tres")
	elif which == "nice":
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_nice.tres")


func _on_kassa_speak_on_interact() -> void:
	if _is_store_empty() and unpaid_items.is_empty():
		SOL.dialogue("cashier_%s_store_empty" % store_cashier.cashier)
		return
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
	text += "total: " + str(total) + "\n"
	var silver: int = DAT.get_data("silver", 0)
	if silver < total:
		text += "[color=red]"
	var svtext := "silver: "
	if randf() < 0.0002:
		svtext = "liver: "
	if total > 0:
		text += svtext + str(silver) + "\n"
	shopping_list.text = text


# final warning. unless you go back and run into the area again
func _on_stealing_area_entered(body: Node2D) -> void:
	if body is OverworldCharacter and body.random_movement:
		var tw := create_tween()
		tw.tween_property(body, "modulate:a", 0.0, 1.0)
		tw.tween_callback(func(): body.queue_free())
		return
	store_cashier.warn()


func _on_room_gate_entered() -> void:
	var stolen_profit := 0
	for i in unpaid_items:
		stolen_profit += ResMan.get_item(i).price
	DAT.incri("%s_profit_stolen" % store_cashier.cashier, stolen_profit)
	if wet_slop:
		DAT.set_data("store_cleanup_started_second", DAT.seconds)


# mean cashier steal cutscene
func dothethingthething() -> void:
	decor.dothethingthething()


func is_mail_man_here() -> bool:
	if DAT.get_data("you_gotta_see_the_water_drain", false):
		return false
	if DAT.get_data("biking_games_finished", 0) < 1:
		return false
	var inter := DAT.seconds % 500
	return inter > 125 and inter < 225


func _mail_man_check() -> void:
	if not is_instance_valid(mail_man):
		mail_man_check_timer.stop()
		return
	if not is_mail_man_here():
		mail_man.path_container = $Decor/MailManExitPath
	pass


func _is_store_empty() -> bool:
	for shelf in shelves:
		if int(shelf.type) != 0:
			return false
	return true


func _restroom_door_knocked() -> void:
	if not unpaid_items.is_empty():
		restroom_door_area.destination = &""
	else:
		restroom_door_area.destination = &"store_restroom"
