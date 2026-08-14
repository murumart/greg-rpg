class_name NotPredicate extends Predicate

@export var what: Predicate


func _internal_check() -> String:
	assert(is_instance_valid(what))
	if what.check() == SUCCESS:
		return fail_string
	return SUCCESS
