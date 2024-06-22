class_name GlassExchange extends Exchange

@export var glass_required: int


func has_input(inventory: Array) -> bool:
	return super(inventory) and _get_questing().glass >= glass_required


func _criteria_statement(informations: Array) -> void:
	super(informations)
	if glass_required:
		informations.append("- %s glass" % glass_required)


func _get_questing() -> ForestQuesting:
	return DAT.get_data("forest_questing", null)

