extends Control

var game : BikingGame

@onready var road_parts := $RoadParts
@onready var hell_menu := $HellMenu

@onready var road := $RoadParts/Road
@onready var pointer := $RoadParts/Pointer
@onready var meter_counter := $RoadParts/MeterCounter
@onready var health_bar := $HealthBar
@onready var coin_label := $CounterContainer/CoinCounter/CoinCounterLabel
@onready var mail_label := $CounterContainer/MailCounter/MailCounterLabel
@onready var snail_label := $CounterContainer/SnailCounter/SnailCounterLabel
@onready var hell_snail_label := $HellMenu/SnailCounterLabel

var inventory_open := false
@onready var inventory_panel := $UsingItemPanel
@onready var items_container := $UsingItemPanel/ItemsContainer
@onready var pointing_hand := $UsingItemPanel/PouintingHand
var chosen_item := 0


func _ready() -> void:
	game = get_parent()
	assert(game, "i need a game parent to function here")


func _input(event: InputEvent) -> void:
	if inventory_open:
		var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		chosen_item = wrapi(chosen_item + int(move.x), 0, game.inventory.size())
		pointing_hand.global_position.x = items_container.get_child(chosen_item).global_position.x + 8
		
		if event.is_action_pressed("ui_accept"):
			if game.inventory.size() > 0:
				use_item(game.inventory[chosen_item])


func display_health(new_value: float) -> void:
	var old_value : float = health_bar.value
	var tw := create_tween()
	var tw2 := create_tween()
	tw.tween_property(health_bar, "value", new_value, absf(new_value - old_value) * 0.007)
	tw2.tween_property(health_bar, "modulate", Color("#ff0000" if new_value < old_value else "#00ff00"), 0.4)
	tw2.tween_property(health_bar, "modulate", Color("#ffffff"), 0.4)


func display_coins(new_value: float) -> void:
	coin_label.text = str(new_value)


func display_mail(new_value: float) -> void:
	mail_label.text = str(new_value)


func display_snail(new_value: float) -> void:
	snail_label.text = str(new_value)


func display_hell_snail(new_value: float) -> void:
	hell_snail_label.text = "%s/%s" % [new_value, game.SNAILS_TO_ESCAPE_HELL]


func set_pointer_pos(percent: float) -> void:
	pointer.global_position.x = remap(percent, 0.0, 1.0, road.position.x, road.position.x + road.size.x)
	meter_counter.text = str(roundi(percent * 800))


func open_item_menu() -> void:
	print("opeining")
	update_item_menu()
	inventory_panel.show()
	set_deferred("inventory_open", true)


func close_item_menu() -> void:
	inventory_panel.hide()
	set_deferred("inventory_open", false)


func update_item_menu() -> void:
	for mike_from_game_from_scracth in items_container.get_child_count():
		var child := items_container.get_child(mike_from_game_from_scracth)
		child.texture = null
		if mike_from_game_from_scracth < game.inventory.size():
			child.texture = DAT.get_item(game.inventory[mike_from_game_from_scracth]).texture


# pure barbarism
func use_item(item: String) -> void:
	game.inventory.erase(item)
	update_item_menu()
	if item == "tape":
		game.bike.heal(roundi(45/2.0))


func open_hell_menu() -> void:
	var tw1 := create_tween()
	var tw2 := create_tween()
	tw1.tween_property(hell_menu, "position:y", 2.0, 2.0)
	tw2.tween_property(road_parts, "position:y", -26.0, 2.0)


func close_hell_menu() -> void:
	var tw1 := create_tween()
	var tw2 := create_tween()
	tw1.tween_property(hell_menu, "position:y", -40.0, 2.0)
	tw2.tween_property(road_parts, "position:y", -26.0, 2.0)


