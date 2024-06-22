class_name GlassExchange extends Exchange

@export var glass_required: int
@export var add_to_perk: KFPair


func has_input(inventory: Array) -> bool:
	return super(inventory) and _get_questing().glass >= glass_required


func _criteria_statement(informations: Array) -> void:
	super(informations)
	if glass_required:
		informations.append("- %s glass" % glass_required)


func _returns_statement(informations: Array) -> void:
	super(informations)
	if add_to_perk:
		informations.append(str("- ", add_to_perk.key.replace("_", " "), " +", add_to_perk.value))



func _grant_parts(inventory: Array) -> void:
	super(inventory)
	if add_to_perk:
		var questing := _get_questing()
		questing.add_perk({add_to_perk.key: add_to_perk.value})


func _remove_payment(inventory: Array) -> void:
	super(inventory)
	_get_questing().glass -= glass_required


func _get_questing() -> ForestQuesting:
	return DAT.get_data("forest_questing", null)

