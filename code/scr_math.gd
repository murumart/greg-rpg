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


# y = 138.3066 + (2.146303 - 138.3066)/(1 + (x/160.4427)^1.068135)
static func method_29193(x: float):
	var var_1 := 138.3066
	var var_2 := 2.146303
	var var_3 := 160.4427
	var var_4 := 1.068135
	var y := var_1 + (var_2 - var_1)/(1 + pow(x/var_3, var_4))
	return y


static func sign_symbol(x) -> String:
	return "+" if x > 0 else "-"


static func reaap(a : Array, b: Variant) -> Array:
	a.append(b)
	return a
