class_name PickableItem extends InteractionArea

@export var item_type := &""


func _ready() -> void:
	assert(ResMan.items.has(item_type), "item type doesn't exist")
	$Sprite2D.texture = ResMan.get_item(item_type).texture


func _on_on_interact() -> void:
	DAT.grant_item(item_type)
	queue_free()
