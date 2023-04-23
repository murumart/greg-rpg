extends Node2D

var elements := Elements.new()


func _ready() -> void:
	var el := 0
	print(elements.get_period(el))
	print(elements.get_valence(el))
	print(elements.get_group(el))
	print(elements.element_names)
	print(elements.element_abbrs)


func c(arr : Array) -> Compound:
	return Compound.new(arr)
