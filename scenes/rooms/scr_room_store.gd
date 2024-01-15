extends Room

# the store room scene
# copied over from old greg and adjusted

# item types stored here
const HEALING_ITEMS := ["medkit", "plaster", "pills", "cough_syrup"]
const FOOD_ITEMS := ["muesli", "mueslibar", "bread", "salt"]
const BUILDING_ITEMS := ["tape", "glue"]

const WAIT_UNTIL_RESTOCK := 300
const WAIT_UNTIL_CASHIER_SWITCH := 420

var item_storage = []

@onready var shelves = $Shelves.get_children()
# this is a dictionary containing a huge list of all shelves in the store
# which are stored as dictionaries that store the item type and count and such
var store_data := {}

var store_cashier := StoreCashier.new()

@onready var ui := $StoreUi
@onready var shopping_list := $StoreUi/ShoppingList

@onready var cashier_sprite := $Kassa/Cashier/Sprite
@onready var cashier := $Kassa/Cashier


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
	neighbour_wife_position()
	if not store_cashier.cashier == "dead":
		SND.play_song("air_conditioning", 1.0, {
			play_from_beginning = true,
			start_volume = 0,
		})


func set_store_wall_colours():
	var store_wall := $InteriorTiles as TileMap
	var mn = DAT.get_data("nr", 0)/100.0
	
	var color = Color(mn, 0.5, 0.8).lightened(0.2)
	
	store_wall.set_layer_modulate(1, color)


func _on_item_taken(ittype: String):
	if ittype in DAT.item_dict:
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
	if DAT.get_data("fighting_cashier", false):
		DAT.set_data("noticed_cashier_gone", DAT.seconds)
		return
	var store_shelf_count := shelves.size()
	var arrays := [HEALING_ITEMS, FOOD_ITEMS, BUILDING_ITEMS]
	
	store_data["shelves"] = []
	store_data["shelves"].clear() # for good measure i guess :dace:
	for i in store_shelf_count:
		var inventory = []
		var from: Array = arrays.pick_random()
		var fromremove := from.duplicate()
		for J in randi()%4:
			if fromremove.size() < 1: continue
			var item = fromremove.pick_random()
			if item not in DAT.item_dict.keys(): continue
			fromremove.erase(item)
			var itemprice = DAT.get_item(item).price
			var itemcount = roundi(minf(3000/pow(itemprice, 1.5) + 1, 8))
			if itemcount < 1: continue
			inventory.append({"item": item,"count": itemcount})
		var itemtype = 0
		if from in arrays:
			itemtype = arrays.find(from) + 1
		else: itemtype = 0
		if inventory.size() < 1: itemtype = 0
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
	if DAT.get_data("fighting_cashier", false):
		cashier.queue_free()
		store_cashier.cashier = "dead" # happens
		DIR.sej(144, 1)
		return
	# load the current cashier based on their schedule
	if wrapi(DAT.seconds, 0, WAIT_UNTIL_CASHIER_SWITCH * 2) > WAIT_UNTIL_CASHIER_SWITCH:
		store_cashier.cashier = "mean"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_mean.tres")
	else:
		store_cashier.cashier = "nice"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_nice.tres")


func _on_kassa_speak_on_interact() -> void:
	store_cashier.speak()


func _on_kassa_finished() -> void:
	update_shopping_list()


# display shopping cart items in the top right of the screen
func update_shopping_list() -> void:
	var unpaid_items: Array = DAT.get_data("unpaid_items", [])
	var temp_dict := {}
	for i in unpaid_items:
		if i in temp_dict:
			temp_dict[i] += 1
		else:
			temp_dict[i] = 1
	var text := "[right]"
	for i in temp_dict:
		text += "%s x %s\n" % [DAT.get_item(i).name, temp_dict[i]]
	shopping_list.text = text


# final warning. unless you go back and run into the area again
func _on_stealing_area_entered(_body: Node2D) -> void:
	store_cashier.warn()


func _on_room_gate_entered() -> void:
	var stolen_profit := 0
	for i in DAT.get_data("unpaid_items", []):
		stolen_profit += DAT.get_item(i).price
	DAT.incri("%s_profit_stolen" % store_cashier.cashier, stolen_profit)


# mean cashier steal cutscene
func dothethingthething() -> void:
	var particles := $Kassa/Cashier/WLIParticles
	SND.play_song("ac_scary", 0.2, {pitch_scale = 0.56})
	SND.play_sound(preload("res://sounds/spirit/wli_up.ogg"))
	$Kassa/Cashier/HoverAnimation.play("hover")
	particles.show()
	var movewt := create_tween()
	var tw := create_tween()
	var tw2 := create_tween()
	movewt.tween_property(cashier, "global_position", Vector2(0, 48), 1.0)
	cashier.self_modulate.a = 0.0
	particles.modulate.a = 0.0
	tw.tween_property(cashier, "self_modulate:a", 1.0, 3.0)
	tw2.tween_property(particles, "modulate:a", 1.0, 1.0)
	cashier.random_movement = false
	await tw2.step_finished
	SOL.dialogue("cashier_mean_mean" + store_cashier.addrepeat())
	await SOL.dialogue_closed
	SND.play_sound(preload("res://sounds/spirit/wli_down.ogg"))
	SND.play_song("", 2000)
	await get_tree().create_timer(2.0).timeout
	LTS.enter_battle(BattleInfo.new().set_background("store")\
	.set_enemies(["cashier_mean"]).set_music("entirely_just"))
	DAT.force_data("mean_cashier_saw_you_steal", true)
	DAT.free_player("cashier_revenge")
	DAT.set_data("fighting_cashier", true)


# the neighbour wife can appear in the store
func neighbour_wife_position() -> void:
	var neighbour_wife := $NeighbourWife
	if store_cashier.cashier == "dead":
		neighbour_wife.queue_free()
		return
	var time := wrapi(DAT.seconds, 0, DAT.NEIGHBOUR_WIFE_CYCLE)
	if time < DAT.NEIGHBOUR_WIFE_CYCLE / 2:
		neighbour_wife.queue_free()

