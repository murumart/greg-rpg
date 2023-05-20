extends RefCounted
class_name Math

# math operations that can be useful
# most of these are only used in like 1 place forever lol

const LEVEL_UP_CURVE := preload("res://resources/res_levelup_curve.tres")


static func num_string_type(input: String) -> int:
	if input.is_valid_float():
		return TYPE_FLOAT
	elif input.is_valid_int():
		return TYPE_INT
	else: return TYPE_STRING


# get either -1, 0, 1, 2 to represent the 4 cardinal directions
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


# append to an array and return that array
static func reaap(a : Array, b: Variant) -> Array:
	a.append(b)
	return a


# i guess it's not actually shorter than writing it out
static func inrange(x, a, b) -> bool:
	return x >= a and x <= b


static func süsarv() -> float:
	var stri := OS.get_unique_id()
	var nr := 1.0
	for l in stri:
		if l.is_valid_float():
			nr += float(l)
		else:
			nr += l.to_ascii_buffer()[0]
	return stri.length() / nr


# shuffle an array using an rng's seed value
static func determ_shuffle(arr : Array, rng: RandomNumberGenerator) -> Array:
	var new_array := []
	for i in arr.size():
		var x = arr[rng.randi() % arr.size()]
		new_array.append(x)
		arr.erase(x)
	return new_array


static func mult_arr(arr: Array, x: int) -> Array:
	var a := []
	for i in x: a.append_array(arr)
	return a
	


