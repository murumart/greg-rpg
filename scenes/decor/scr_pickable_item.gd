class_name PickableItem extends InteractionArea

@export var item_type := &""
@export var save := false


func _ready() -> void:
	assert(ResMan.items.has(item_type), "item type doesn't exist")
	if save and DAT.get_data(get_save_key(), false):
		queue_free()
		return
	$Sprite2D.texture = ResMan.get_item(item_type).texture


func _on_on_interact() -> void:
	DAT.grant_item(item_type)
	if save:
		DAT.set_data(get_save_key(), true)
	queue_free()


func get_save_key() -> String:
	return "pickable_item_" + name + "_in_" + LTS.get_current_scene().name + "_picked"
