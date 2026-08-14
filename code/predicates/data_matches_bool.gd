class_name DataMatchesBoolPredicate extends Predicate

@export var data_key: StringName
@export var matches: bool


func _internal_check() -> String:
	var dat: Variant = DAT.get_data(data_key, false)
	if typeof(dat) != TYPE_BOOL:
		return fail_string
	if dat == matches:
		return SUCCESS
	return fail_string
