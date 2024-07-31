extends Control

# mail man kiosk again
# i',m not commenting this any more than it already is. good lcuk

const MAX_INV_SIZE := 3

signal closed

var game #: BikingGame but NOT because cyclic resource inclusion!!! ahhahaaha

const REF_BUTTON_LOAD := preload("res://scenes/tech/scn_reference_button.tscn")

@onready var dlbox := $DialogueBox
@onready var button_container := $ScrollContainer/ButtonContainer
@onready var item_info_label := $ItemInfoLabel
@onready var item_picture := $ItemPanel/Sprite2D

const RESETTABLE_DAT_VARIABLES := [
	"biking_hell_mentioned",
	"biking_hells2_mentioned",
	"biking_hells3_mentioned",
	"biking_hellsmore_mentioned",
	"biking_small_talked",
]

var stage := -1
var ending := false

var possible_items := [&"tape", &"magnet", &"cough_syrup", &"milk", &"salt"]
var items_available := []
var possible_perks := [
	&"snail_repel",
	&"snail_bail",
	&"less_logs",
	&"nicer_roads",
	&"fast_earner",
	&"mail_attraction",
	&"sauce_mail"]
var perks_available := []
var deletion_possible := false


func _ready() -> void:
	if game and game.get_meter() >= game.ROAD_LENGTH - 15:
		ending = true
	item_picture.texture = null
	item_picture.get_parent().hide()
	item_info_label.text = ""
	items_available = gen_items()
	perks_available = gen_perks()
	dlbox.prepare_dialogue(get_welcome_message())
	DAT.set_data("last_kiosk_open_second", DAT.seconds)
	await dlbox.dialogue_closed
	if dlbox.current_choice == "browse":
		dlbox.prepare_dialogue("biking_browse")
		load_items()
	else:
		bye()


func load_items() -> void:
	stage = 1
	for c in button_container.get_children():
		c.hide()
		c.queue_free()
	Math.load_reference_buttons(items_available, [button_container],
			_reference_button_pressed, _on_button_reference_received,
			{"item": true, "custom_pass_function": item_names})
	button_container.get_child(0).call_deferred("grab_focus")


func load_perks() -> void:
	stage = 2
	#load_reference_buttons(perks_available, [button_container])
	Math.load_reference_buttons(perks_available, [button_container],
			_reference_button_pressed, _on_button_reference_received,
			{"us2space": true, "custom_pass_function": perk_names})


# this is horrible but I do not have the mental capacity at the moment
# future me, do your thing
# fuck you past me
# go to hell
# future future me also go to hell lol I'm not improving this
# future future me here. this could be a lot worse. not touching it tho
func bye(choseperk := false) -> void:
	if ending:
		dlbox.prepare_dialogue("biking_end")
		await dlbox.dialogue_closed
		closed.emit()
		for v in RESETTABLE_DAT_VARIABLES:
			DAT.set_data(v, false)
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
	if not game:
		return "biking_welcome_1"
	var kiosks_opened: int = game_get("kiosks_activated", 0)
	var bike = game_get("bike")
	var health: float = bike.health / float(bike.max_health)
	if ending:
		SND.play_song("victory", 1.0, {"start_volume": 1.0, "play_from_beginning": true})
		return "biking_last_stop"
	if health < 0.24:
		return "biking_welcome_lowhealth"
	if game_get("snails_hit", 0) - float(game_get("snails_until_hell")) > -3:
		return "biking_welcome_snailwarning"
	if game_get("hells_survived", 0) == 1 and not DAT.get_data("biking_hell_mentioned", false):
		DAT.set_data("biking_hell_mentioned", true)
		return "biking_welcome_hellmention"
	if game_get("hells_survived", 0) == 2 and not DAT.get_data("biking_hells2_mentioned", false):
		DAT.set_data("biking_hells2_mentioned", true)
		return "biking_welcome_2hells"
	if game_get("hells_survived", 0) == 3 and not DAT.get_data("biking_hells3_mentioned", false):
		DAT.set_data("biking_hells3_mentioned", true)
		return "biking_welcome_3hells"
	if game_get("hells_survived", 0) > 3 and not DAT.get_data("biking_hellsmore_mentioned", false):
		DAT.set_data("biking_hellsmore_mentioned", true)
		return "biking_welcome_morehells"
	if kiosks_opened == 1:
		return "biking_welcome_1"
	if DAT.seconds - DAT.get_data("last_kiosk_open_second", 0) > 60 + 30 + 60:
		return "biking_welcome_afterwhile"
	if Math.inrange(kiosks_opened, 2, 3):
		if DAT.get_data("witnessed_ushanka_guy_cutscene", false) and not DAT.get_data("biking_small_talked"):
			DAT.set_data("biking_small_talked", true)
			var p := DAT.get_data("mail_man_smalltalk_progress", 0) as int
			if SOL.dialogue_exists("biking_welcome_smalltalk_" + str(p + 1)):
				p += 1
				DAT.set_data("mail_man_smalltalk_progress", p)
				return "biking_welcome_smalltalk_" + str(p)
		return "biking_welcome_" + str((randi() % 7) + 2)
	if kiosks_opened == 4:
		return "biking_welcome_beforelast"
	return "biking_welcome_1"


func gen_items() -> Array:
	var arr := []
	for i in randi_range(4, 6):
		arr.append(possible_items.pick_random())
	arr.append(&"leave")
	return arr


func gen_perks() -> Array:
	var reference := possible_perks.duplicate()
	if randf() <= 0.1:
		reference.append(&"super_mail")
	var arr := []
	for i in 3:
		var choice := reference.pop_at(randi() % reference.size()) as StringName
		arr.append(choice)
	arr.append(&"leave")
	return arr


func item_names(opt := {}) -> void:
	if opt.button.reference == &"leave":
		opt.button.text = &"leave"
		opt.button.modulate = Color("#888888")
		return
	if opt.button.reference == &"delete":
		opt.button.text = &"delete"
		opt.button.modulate = Color("#888888")
		return
	opt.button.text = opt.reference.left(8)
	if opt.reference in ResMan.items:
		opt.button.text = ResMan.get_item(opt.reference).name.left(8)


func perk_names(opt := {}) -> void:
	if opt.button.reference == &"leave":
		opt.button.text = &"leave"
		opt.button.modulate = Color("#888888")
		return
	opt.button.text = opt.reference.replace("_", " ")


func _reference_button_pressed(reference) -> void:
	if reference == &"leave":
		bye()
		return
	if reference == &"delete":
		delete_items()
		return
	if stage == 1:
		item_reference_pressed(reference)
	elif stage == 2:
		perk_reference_pressed(reference)


func item_reference_pressed(reference) -> void:
	var item := ResMan.get_item(reference)
	var price = roundi(item.price / 4.0)
	var inventory: Array = game_get("inventory", [])
	var silver: int = game_get("silver_collected", 0)
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
				if not deletion_possible:
					items_available.insert(items_available.size() - 1, &"delete")
					load_items()
					deletion_possible = true
				await dlbox.dialogue_closed
				button_container.get_child(0).grab_focus()
	dlbox.current_choice = ""


func delete_items() -> void:
	var inventory: Array = game_get("inventory", [])
	inventory.clear()
	items_available.erase(&"delete")
	load_items()
	dlbox.prepare_dialogue("biking_delete_items")
	await dlbox.dialogue_closed
	button_container.get_child(0).grab_focus()
	deletion_possible = false


func perk_reference_pressed(reference) -> void:
	get_viewport().gui_release_focus()
	game_set("current_perk", reference)
	bye(true)


func _on_button_reference_received(reference) -> void:
	if reference == &"leave" or reference == &"delete":
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
%s silver" % [ResMan.get_item(reference).name, roundi(ResMan.get_item(reference).price / 4.0)]
	item_picture.get_parent().show()
	item_picture.texture = ResMan.get_item(reference).texture


func perk_reference_received(reference) -> void:
	item_info_label.text = ""
	item_picture.get_parent().hide()
	var dialogue_name: String = "biking_perk_%s" % reference
	if !dialogue_name in dlbox.dialogues_dict.keys():
		dialogue_name = "biking_perk_else"
	dlbox.skip()
	dlbox.loaded_dialogue = null
	dlbox.prepare_dialogue(dialogue_name)


func game_get(thing: String, default: Variant = null) -> Variant:
	if !game:
		return default
	return game.get(thing)


func game_set(thing: String, to: Variant) -> void:
	if !game:
		printerr("no game")
		return
	game.set(thing, to)


func game_call(method: String, arguments: Array = []) -> void:
	if !game:
		printerr("no game")
		return
	game.callv(method, arguments)


