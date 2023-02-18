extends Room

const WAIT_UNTIL_RESTOCK := 300

var item_storage = []

@onready var shelves = $Shelves.get_children()
var store_data := {}

var store_cashier := StoreCashier.new()


func _ready():
	DAT.set_data("silver", 3000)
	super._ready()
	set_store_wall_colours()
	
	for s in shelves:
		s.item_taken.connect(_on_item_taken)
	
	load_store_data()


func set_store_wall_colours():
	var store_wall = $Wall
	var mn = DAT.A.get("nr", 0)/100.0
	
	var color = Color(mn, 0.5, 0.8).lightened(0.2)
	
	store_wall.modulate = color


func _on_item_taken(ittype: String):
	if ittype in DAT.item_dict:
		DAT.set_data("unpaid_items", Math.reaap(DAT.get_data("unpaid_items", []), ittype))


func load_store_data():
	store_data = DAT.A.get("store_data", {})
	check_restock()
	if store_data.is_empty():
		restock()
	for s in store_data.get("shelves", []).size():
		var shelf = store_data.get("shelves")[s]
		shelves[s].inventory = shelf["inventory"]
		shelves[s].set_type(shelf["type"])


func restock() -> void:
	var store_shelf_count := shelves.size()
	
	var healing_items := ["medkit", "plaster", "pills"]
	var food_items := ["gummy_worm", "porridge", "milkshake"]
	var building_items := []
	var arrays := [healing_items, food_items, building_items]
	
	store_data["shelves"] = []
	store_data["shelves"].clear()
	for i in store_shelf_count:
		var inventory = []
		var from : Array = arrays.pick_random()
		var fromremove := from.duplicate()
		for J in randi()%4:
			if fromremove.size() < 1: continue
			var item = fromremove.pick_random()
			if item not in DAT.item_dict.keys(): continue
			fromremove.erase(item)
			var itemprice = DAT.get_item(item).price
			var itemcount = roundi(minf(3000/pow(itemprice, 1.5) + 1, 8))
			print(itemcount)
			if itemcount < 1: continue
			inventory.append({"item": item,"count": itemcount})
		var itemtype = 0
		if from == healing_items: itemtype = 1
		elif from == food_items: itemtype = 2
		elif from == building_items: itemtype = 3
		else: itemtype = 0
		if inventory.size() < 1: itemtype = 0
		store_data["shelves"].append({"inventory": inventory, "type": itemtype})
	DAT.set_data("store_data", store_data)
	DAT.set_data("store_restock_second", DAT.seconds)


func save_me():
	print("store saving data!")
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
	if DAT.seconds - DAT.A.get("store_restock_second", -3000) >= WAIT_UNTIL_RESTOCK:
		restock()


func _on_kassa_speak_on_interact() -> void:
	store_cashier.speak()
