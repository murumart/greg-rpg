extends RefCounted
class_name Math

# math operations that can be useful


static func num_string_type(input: String) -> int:
	if input.is_valid_float():
		return TYPE_FLOAT
	elif input.is_valid_int():
		return TYPE_INT
	else: return TYPE_STRING


static func dir_from_rot(rotation_radians: float) -> int:
	return wrapi(int(roundi(rotation_radians/PI*2)), -1, 3)
