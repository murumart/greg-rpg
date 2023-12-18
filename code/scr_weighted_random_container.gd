class_name WeightedRandomContainer extends Resource

@export var elements: Array[WRPair] = []
var items: Array[StringName]: get = _get_items
var weights: Array[float]: get = _get_weights


func get_random_id() -> StringName:
	return Math.weighted_random(items, weights)


func _get_items() -> Array[StringName]:
	var ar: Array[StringName] = []
	for el in elements:
		ar.append(el.id)
	return ar


func _get_weights() -> Array[float]:
	var ar: Array[float] = []
	for el in elements:
		ar.append(el.weight)
	return ar
