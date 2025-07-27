class_name GlassExchange extends Exchange

@export var glass_required: int
@export var gold_required: int
@export var add_to_perk: KFPair
@export var perk_time: int = 0
@export_multiline var description: String


func has_input(inventory: Array) -> bool:
	return super(inventory) and _get_questing().glass >= glass_required and inventory.count(&"gold") >= gold_required


func _criteria_statement(informations: Array) -> void:
	super(informations)
	if glass_required:
		informations.append("- %s glass" % glass_required)
	if gold_required:
		informations.append("- %s gold" % gold_required)


func _returns_statement(informations: Array) -> void:
	super(informations)
	if add_to_perk:
		informations.append(str("- ", add_to_perk.key.replace("_", " "), " +", add_to_perk.value))


func _grant_parts(inventory: Array) -> void:
	super(inventory)
	if add_to_perk:
		var questing := _get_questing()
		if perk_time > 0:
			var p := questing.Perk.new(add_to_perk.key, add_to_perk.value)
			p.time_left = perk_time
			questing.append_perk(p)
		else:
			var _p := questing.add_perk(add_to_perk.key, add_to_perk.value)


func _remove_payment(inventory: Array) -> void:
	super(inventory)
	_get_questing().glass -= glass_required
	for x in gold_required:
		assert(&"gold" in inventory)
		inventory.erase(&"gold")


func _get_questing() -> ForestQuesting:
	return DAT.get_data("forest_questing", null)
