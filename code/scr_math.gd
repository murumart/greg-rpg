extends RefCounted
class_name Math


static func num_string_type(input: String) -> int:
	if input.is_valid_float():
		return TYPE_FLOAT
	elif input.is_valid_int():
		return TYPE_INT
	else: return TYPE_STRING
