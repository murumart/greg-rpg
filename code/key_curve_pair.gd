class_name KeyCurve extends Resource

@export var key := &""
@export var curve: Curve


static func get_curve_by_key(pairs: Array[KeyCurve], key: StringName) -> Curve:
	for kkp in pairs:
		if kkp.key == key:
			return kkp.curve
	return null


