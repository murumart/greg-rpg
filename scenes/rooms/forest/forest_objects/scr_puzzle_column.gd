extends StaticBody2D

signal finished

@export var interaction_area: InteractionArea

var active: bool:
	get: return DAT.get_data("forest_save", {}).get(_key(), false)
	set(to): DAT.get_data("forest_save", {})[_key()] = to


func _ready() -> void:
	interaction_area.interacted.connect(_interacted)


func _interacted() -> void:
	if active:
		return


static func _kn() -> String:
	return "pcul"


func _key() -> String:
	return _kn() + "_" + str(DAT.get_data("forest_depth", 0)) + "_played"
