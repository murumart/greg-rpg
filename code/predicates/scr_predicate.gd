@abstract class_name Predicate extends Resource

const SUCCESS := ""

@export var fail_string: String = "?"
@export var and_with: Predicate
@export var or_with: Predicate


## returns Predicate.SUCCESS on success, any other string on failure
func check() -> String:
	if and_with != null:
		var andc := and_with.check()
		if andc != SUCCESS:
			return andc
	if or_with != null:
		if or_with.check() == SUCCESS:
			return SUCCESS
	return _internal_check()


@abstract func _internal_check() -> String
