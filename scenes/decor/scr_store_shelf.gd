@tool
extends Node2D

# who the fuck wrote this? I did. sometime in the late summer of last year.
# maybe I should've written a new system from scratch... . noooo... no. . .. 

signal item_taken

enum types {EMPTY, HEALING, FOOD, BUILDING}
var typenames := {
	types.EMPTY: "empty",
	types.HEALING: "healing",
	types.FOOD: "food",
	types.BUILDING: "building",
}

const PRODUCT_PATH := "res://sprites/world/object/store_shelves/spr_%s_products.png"
@export_enum("empty", "healing", "food", "building") var type := 0: set = set_type
@export var inventory : Array = []


func set_type(to: int):
	type = to
	if to == types.EMPTY:
		$Foreground.texture = null
		return
	var texture : Texture = load(PRODUCT_PATH % typenames.get(type))
	if texture:
		$Foreground.texture = texture
	else:
		print("no texture %s available" % (PRODUCT_PATH % typenames.get(type)))


# this sure is one of the functions in greg
func _on_interaction_area_on_interact() -> void:
	print(self.name, ": ", inventory)
	var name_keys_dict := {}
	
	# if there are no items on the shelf:
	if type == types.EMPTY:
		SOL.dialogue("store_shelf_empty")
		return
	
	# updating dialogue to make sense in current context - stuffing type name in
	SOL.dialogue_box.dial_concat("store_shelf_start", 0, [typenames[type]])
	SOL.dialogue_box.dial_concat("store_shelf_start", 1, [typenames[type]])
	SOL.dialogue_box.adjust("store_shelf_start", 1, "choices", []) # reset choices
	var text := ""
	var choices := []
	for i in inventory.size(): # every available item
		var item = inventory[i]
		# item["item"] accesses an item dictionary's type id
		var item_name = DAT.get_item(item["item"]).name
		var item_price = DAT.get_item(item["item"]).price
		name_keys_dict[item_name] = item["item"]
		choices.append(item_name)
		if len(text) > 1:
			text += "; " # separating listings
		# we show the item's name and price
		text += "%s - %s silver" % [tr(item_name), item_price]
	SOL.dialogue_box.adjust("store_shelf_start", 1, "text", text)
	choices.append("cancel") # add a cancel choosing option
	SOL.dialogue_box.adjust("store_shelf_start", 1, "choices", choices)
	
	SOL.dialogue("store_shelf_start")
	
	await SOL.dialogue_closed
	
	var choice := SOL.dialogue_box.current_choice
	if not (choice == "cancel" or choice == "no"):
		SOL.dialogue_box.dial_concat("store_shelf_confirm", 0, [choice])
		
		SOL.call_deferred("dialogue", "store_shelf_confirm")
		
		await SOL.dialogue_closed
		
		if not choice == "no": # another chance to not take the item
			take_item(name_keys_dict.get(choice))
			# remove item from the shelf inventory
			for i in inventory:
				if i["item"] == name_keys_dict[choice]:
					i["count"] -= 1
					if i["count"] < 1:
						inventory.erase(i)
			if inventory.size() < 1:
				set_type(0)


func take_item(ittype: StringName):
	emit_signal("item_taken", ittype)

