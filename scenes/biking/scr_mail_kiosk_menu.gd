extends Control

signal closed

const REF_BUTTON_LOAD := preload("res://scenes/tech/scn_reference_button.tscn")

@onready var dlbox := $DialogueBox
@onready var button_container := $ScrollContainer/ButtonContainer
@onready var item_info_label := $ItemInfoLabel
@onready var item_picture := $ItemPanel/Sprite2D

var possible_items := ["tape", "magnet"]
var items_available := []


func _ready() -> void:
	item_picture.texture = null
	item_picture.get_parent().hide()
	item_info_label.text = ""
	
	dlbox.prepare_dialogue(get_welcome_message())
	await dlbox.dialogue_closed
	
	if dlbox.current_choice == "browse":
		dlbox.prepare_dialogue("biking_browse")
		items_available = gen_items()
		load_reference_buttons(items_available, [button_container], {"item": true})
		button_container.get_child(0).grab_focus()
	else:
		dlbox.prepare_dialogue("biking_bye_1")
		await dlbox.dialogue_closed
		closed.emit()
		queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		return


func get_welcome_message() -> String:
	return "biking_welcome_1"


func gen_items() -> Array:
	var arr := []
	for i in randi_range(4, 6):
		arr.append(possible_items.pick_random())
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
		elif reference is String and options.get("item", false):
			refbutton.text = DAT.get_item(reference).name
		else:
			refbutton.text = str(reference)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	var item := DAT.get_item(reference)
	dlbox.dial_concat("biking_do_you_wish_to_buy", 0, [item.name])
	dlbox.prepare_dialogue("biking_do_you_wish_to_buy")
	
	await dlbox.dialogue_closed
	if dlbox.current_choice == "no":
		dlbox.prepare_dialogue("biking_browse_2")
		button_container.get_child(0).grab_focus()
	else:
		pass


func _on_button_reference_received(reference) -> void:
	item_info_label.text = "%s
===
%s silver" % [DAT.get_item(reference).name, DAT.get_item(reference).price]
	item_picture.get_parent().show()
	item_picture.texture = DAT.get_item(reference).texture

