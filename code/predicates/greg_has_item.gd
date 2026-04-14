class_name GregHasItemPredicate extends Predicate

@export var item_key: StringName
@export_range(1, 99) var min_count := 1


func _internal_check() -> String:
	assert(ResMan.item_exists(item_key))
	var inventory := ResMan.get_character("greg").inventory
	if inventory.count(item_key) >= min_count:
		return SUCCESS
	return fail_string
