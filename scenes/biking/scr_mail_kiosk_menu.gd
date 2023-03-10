extends Control

const MAX_INV_SIZE := 3

signal closed

var game_reference #: BikingGame but NOT because cyclic resource inclusion!!! ahhahaaha

const REF_BUTTON_LOAD := preload("res://scenes/tech/scn_reference_button.tscn")

@onready var dlbox := $DialogueBox
@onready var button_container := $ScrollContainer/ButtonContainer
@onready var item_info_label := $ItemInfoLabel
@onready var item_picture := $ItemPanel/Sprite2D

var stage := -1
var ending := false

var possible_items := ["tape", "magnet"]
var items_available := []
var possible_perks := [
	"snail_repel",
	"snail_bail",
	"log_repel",
	"nicer_roads",
	"fast_earner",
	"mail_attraction"]
var perks_available := []


func _ready() -> void:
	if game_reference and game_reference.get_meter() >= game_reference.ROAD_LENGTH - 15:
		ending = true
	item_picture.texture = null
	item_picture.get_parent().hide()
	item_info_label.text = ""
	items_available = gen_items()
	perks_available = gen_perks()
	dlbox.prepare_dialogue(get_welcome_message())
	await dlbox.dialogue_closed
	if dlbox.current_choice == "browse":
		dlbox.prepare_dialogue("biking_browse")
		load_items()
	else:
		bye()


func load_items() -> void:
	stage = 1
	load_reference_buttons(items_available, [button_container], {"item": true})
	button_container.get_child(0).call_deferred("grab_focus")


func load_perks() -> void:
	stage = 2
	load_reference_buttons(perks_available, [button_container])


# this is horrible but I do not have the mental capacity at the moment
# future me, do your thing
# fuck you past me
# go to hell
# future future me also go to hell lol I'm not improving this
func bye(choseperk := false) -> void:
	if ending:
		dlbox.prepare_dialogue("biking_end")
		await dlbox.dialogue_closed
		closed.emit()
		queue_free()
		return
		
	if choseperk:
		dlbox.skip()
		dlbox.loaded_dialogue = null
		dlbox.prepare_dialogue("biking_bye_3")
		await dlbox.dialogue_closed
		closed.emit()
		queue_free()
		return
	get_viewport().gui_release_focus()
	dlbox.current_choice = ""
	if stage < 2:
		dlbox.prepare_dialogue("biking_bye_1")
	elif stage == 2:
		dlbox.prepare_dialogue("biking_bye_2")
		dlbox.current_choice = "no"
	await dlbox.dialogue_closed
	if stage == 2:
		closed.emit()
		queue_free()
	if dlbox.current_choice == "no" or stage == 2:
		dlbox.prepare_dialogue("biking_bye_2")
		await dlbox.dialogue_closed
		closed.emit()
		queue_free()
	else:
		dlbox.prepare_dialogue("biking_perks")
		load_perks()
		await dlbox.dialogue_closed
		button_container.get_child(0).call_deferred("grab_focus")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		return


func get_welcome_message() -> String:
	if ending:
		return "biking_last_stop"
	return "biking_welcome_1"


func gen_items() -> Array:
	var arr := []
	for i in randi_range(4, 6):
		arr.append(possible_items.pick_random())
	arr.append("leave")
	return arr


func gen_perks() -> Array:
	var reference := possible_perks.duplicate()
	if randf() <= 0.1:
		reference.append("super_mail")
	var arr := []
	for i in 3:
		var choice : String = reference.pick_random()
		reference.erase(choice)
		arr.append(choice)
	arr.append("leave")
	return arr


func load_reference_buttons(array: Array, containers: Array, options = {}) -> void:
	if options.get("clear", true):
		for container in containers:
			for c in container.get_children():
				c.queue_free()
	var container_nr := 0
	for i in array.size():
		var reference = array[i]
		var refbutton := REF_BUTTON_LOAD.instantiate()
		refbutton.reference = reference
		if reference is Character:
			refbutton.text = reference.name
		elif reference is String and options.get("item", false) and reference != "leave":
			refbutton.text = DAT.get_item(reference).name
		else:
			refbutton.text = str(reference).replace("_", " ")
		if reference == "leave":
			refbutton.modulate = Color("#888888")
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	if reference == "leave":
		bye()
		return
	if stage == 1:
		item_reference_pressed(reference)
	elif stage == 2:
		perk_reference_pressed(reference)


func item_reference_pressed(reference) -> void:
	var item := DAT.get_item(reference)
	var price = roundi(item.price / 4.0)
	var inventory : Array = game_get("inventory", [])
	var silver : int = game_get("silver_collected", 0)
	dlbox.dial_concat("biking_do_you_wish_to_buy", 0, [item.name])
	dlbox.prepare_dialogue("biking_do_you_wish_to_buy")
	get_viewport().gui_release_focus()
	await dlbox.dialogue_closed
	if dlbox.current_choice == "no":
		dlbox.prepare_dialogue("biking_browse_2")
		button_container.get_child(0).grab_focus()
	else:
		if price > silver:
			dlbox.prepare_dialogue("biking_man_not_enough_money")
			await dlbox.dialogue_closed
			button_container.get_child(0).grab_focus()
		else:
			if inventory.size() < MAX_INV_SIZE:
				dlbox.dial_concat("biking_man_buy_item", 0, [item.name])
				dlbox.prepare_dialogue("biking_man_buy_item")
				inventory.append(reference)
				items_available.erase(reference)
				game_set("inventory", inventory)
				game_set("silver_collected", silver - price)
				game_call("update_ui")
				load_items()
				await dlbox.dialogue_closed
				button_container.get_child(0).grab_focus()
			else:
				dlbox.dial_concat("biking_man_not_enough_space", 0, [MAX_INV_SIZE])
				dlbox.prepare_dialogue("biking_man_not_enough_space")
				button_container.get_child(0).grab_focus()
	dlbox.current_choice = ""


func perk_reference_pressed(reference) -> void:
	get_viewport().gui_release_focus()
	game_set("current_perk", reference)
	bye(true)


func _on_button_reference_received(reference) -> void:
	if reference == "leave":
		item_info_label.text = ""
		item_picture.get_parent().hide()
		return
	if stage == 1:
		item_reference_received(reference)
	elif stage == 2:
		perk_reference_received(reference)


func item_reference_received(reference) -> void:
	item_info_label.text = "%s
===
%s silver" % [DAT.get_item(reference).name, roundi(DAT.get_item(reference).price / 4.0)]
	item_picture.get_parent().show()
	item_picture.texture = DAT.get_item(reference).texture


func perk_reference_received(reference) -> void:
	item_info_label.text = ""
	item_picture.get_parent().hide()
	var dialogue_name : String = "biking_perk_%s" % reference
	if !dialogue_name in dlbox.dialogues_dict.keys():
		dialogue_name = "biking_perk_else"
	dlbox.skip()
	dlbox.loaded_dialogue = null
	dlbox.prepare_dialogue(dialogue_name)


func game_get(thing: String, default: Variant = null) -> Variant:
	if !game_reference:
		return default
	if not thing in game_reference:
		return default
	return game_reference.get(thing)


func game_set(thing: String, to: Variant) -> void:
	if !game_reference:
		print("no game")
		return
	game_reference.set(thing, to)


func game_call(method: String, arguments : Array = []) -> void:
	if ! game_reference:
		print("no game")
		return
	game_reference.callv(method, arguments)


