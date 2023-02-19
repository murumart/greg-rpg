extends Room

const WAIT_UNTIL_RESTOCK := 300
const WAIT_UNTIL_CASHIER_SWITCH := 420

var item_storage = []

@onready var shelves = $Shelves.get_children()
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


func set_store_wall_colours():
	var store_wall = $Wall
	var mn = DAT.A.get("nr", 0)/100.0
	
	var color = Color(mn, 0.5, 0.8).lightened(0.2)
	
	store_wall.modulate = color


func _on_item_taken(ittype: String):
	if ittype in DAT.item_dict:
		DAT.set_data("unpaid_items", Math.reaap(DAT.get_data("unpaid_items", []), ittype))
	update_shopping_list()


func load_store_data():
	store_data = DAT.A.get("store_data", {})
	check_restock()
	check_cashier_switch()
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


func check_cashier_switch() -> void:
	print("cashier second: ", (DAT.seconds / float(WAIT_UNTIL_CASHIER_SWITCH)))
	if roundi(DAT.seconds / float(WAIT_UNTIL_CASHIER_SWITCH)) % 2 == 0:
		store_cashier.cashier = "mean"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_mean.tres")
	else:
		store_cashier.cashier = "nice"
		cashier_sprite.sprite_frames = load("res://resources/characters/sfr_cashier_nice.tres")


func _on_kassa_speak_on_interact() -> void:
	store_cashier.speak()


func _on_kassa_finished() -> void:
	update_shopping_list()


func update_shopping_list() -> void:
	var unpaid_items : Array = DAT.get_data("unpaid_items", [])
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


func _on_stealing_area_entered(_body: Node2D) -> void:
	store_cashier.warn()


func _on_room_gate_entered() -> void:
	var stolen_profit := 0
	for i in DAT.A.get("unpaid_items", []):
		stolen_profit += DAT.get_item(i).price
	DAT.incri("%s_profit_stolen" % store_cashier.cashier, stolen_profit)


func dothethingthething() -> void:
	var particles := $Kassa/Cashier/WLIParticles
	SND.play_song("ac_scary", 2, {pitch_scale = 0.56})
	SND.play_sound(preload("res://sounds/spirit/snd_wli_up.ogg"))
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
	SND.play_sound(preload("res://sounds/spirit/snd_wli_down.ogg"))
	await get_tree().create_timer(2.0).timeout
	LTS.enter_battle(BattleInfo.new().set_background("store")\
	.set_enemies(["cashier_mean"]).set_music("entirely_just"))
	DAT.force_data("mean_cashier_saw_you_steal", true)
	DAT.free_player("cashier_revenge")

