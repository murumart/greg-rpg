class_name KeyCurve extends Resource

@export var key := &""
@export var curve: Curve


static func get_curve_by_key(pairs: Array[KeyCurve], key_name: StringName) -> Curve:
	for kkp in pairs:
		if kkp.key == key_name:
			return kkp.curve
	return null


static func create_pair(_key: StringName, _curve: Curve) -> KeyCurve:
	var pp := KeyCurve.new()
	pp.key = _key
	pp.curve = _curve
	return pp


