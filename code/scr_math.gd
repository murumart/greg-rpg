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
	var y := 138.3066 + (2.146303 - 138.3066)/(1 + pow(x/160.4427, 1.068135))
	return y


static func sign_symbol(x) -> String:
	return "+" if x > 0 else "-"


# append to an array and return that array
static func reaap(a: Array, b: Variant) -> Array:
	a.append(b)
	return a


# merge to a dict and return it
static func dmerg(a: Dictionary, b: Dictionary) -> Dictionary:
	a.merge(b, true)
	return a


# return the difference between two dictionaries
static func dictdiff(a: Dictionary, b: Dictionary) -> Dictionary:
	var ret := {}
	var aks := a.keys()
	var bks := b.keys()
	for key in aks:
		if not key in bks:
			ret[key] = a[key]
			continue
		if typeof(a[key]) == typeof(b[key]):
			ret[key] = a[key] - b[key]
	return ret


# i guess it's not actually shorter than writing it out
static func inrange(x, a, b) -> bool:
	return x >= a and x <= b


static func süsarv() -> float:
	var stri := OS.get_unique_id(); var nr := 1.0
	for l in stri:
		if l.is_valid_float(): nr += float(l)
		else: nr += l.to_ascii_buffer()[0]
	return stri.length() / nr


# shuffle an array using an rng's seed value
static func determ_shuffle(arr: Array, rng: RandomNumberGenerator) -> Array:
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


static func party(tab: int) -> Character:
	return DAT.get_character(DAT.get_data("party", ["greg"])[tab])


# this is one ugly funtion
# populates an array of containers with reference button children
static func load_reference_buttons(
		array: Array,
		containers: Array,
		reference_button_press_function: Callable,
		button_reference_receive_function: Callable,
		options := {}
	) -> void:
	var REFERENCE_BUTTON := preload("res://scenes/tech/scn_reference_button.tscn")
	var mouse_interaction := options.get("mouse_interaction", false) as bool
	var text_left := options.get("text_left", 2147483647) as int
	var custom_pass_function = options.get("custom_pass_function", null)
	var us2space := options.get("us2space", false) as bool
	var name_overwrite_array := options.get("name_overwrite_array", []) as Array
	if options.get("clear", true):
		for container in containers:
			for c in container.get_children():
				c.queue_free()
	var container_nr := 0
	for i in array.size():
		var ref = array[i]
		var refbutton := REFERENCE_BUTTON.instantiate() as Button
		refbutton.reference = ref
		refbutton.text = str(ref).left(text_left)
		if name_overwrite_array:
			refbutton.text = str(name_overwrite_array[i]).left(text_left)
		if us2space: refbutton.text = refbutton.text.replace("_", " ")
		if custom_pass_function:
			custom_pass_function.call({
					"button": refbutton,
					"reference": ref,
					"nr": i
				})
		refbutton.connect("return_reference", reference_button_press_function)
		refbutton.connect("selected_return_reference", button_reference_receive_function)
		if mouse_interaction:
			refbutton.mouse_filter = Control.MOUSE_FILTER_STOP
			refbutton.button_mask = MOUSE_BUTTON_MASK_LEFT
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())
	if not options.get("adjust_focus", true): return
	# awaiting in a static function
	await DAT.get_tree().process_frame
	# loop through all buttons again
	for i in containers.size():
		var c = containers[i]
		if not is_instance_valid(c): return
		if c.get_child_count() < 2: return
		for j in c.get_child_count():
			var k = c.get_child(j)
			# if it's the first one in a column, make its top neighbour the
			# last one in the previous column
			if j == 0:
				k.focus_neighbor_top = containers[wrapi(i - 1, 0,
					containers.size())].get_child(-1).get_path()
			# if it's the last one in a column, make its top neighbour the
			# first one in the previous column
			if j + 1 >= c.get_child_count():
				k.focus_neighbor_bottom = containers[wrapi(i + 1, 0,
					containers.size())].get_child(0).get_path()


static func load_reference_buttons_groups(
		array: Array,
		containers: Array,
		reference_button_press_function: Callable,
		button_reference_receive_function: Callable,
		options := {}
	) -> void:
	var conglor := []
	var dict := {}
	for i in array:
		if i in dict.keys(): continue
		dict[i] = array.count(i)
	for i in dict.keys():
		conglor.append(str(dict[i]) + "x " + i)
	options["name_overwrite_array"] = conglor
	load_reference_buttons(dict.keys(), containers, reference_button_press_function, button_reference_receive_function, options)


static func item_name_array(inp: Array) -> Array:
	var ret := []
	for i in inp:
		ret.append(DAT.get_item(i).name)
	return ret


static func spirit_name_array(inp: Array) -> Array:
	var ret := []
	for i in inp:
		ret.append(DAT.get_spirit(i).name)
	return ret


static func character_name_array(inp: Array) -> Array:
	var ret := []
	for i in inp:
		ret.append(DAT.get_character(i).name)
	return ret


static func battle_actor_name_array(inp: Array) -> Array:
	var ret := []
	for i in inp:
		i = i as BattleActor
		ret.append(i.actor_name)
	return ret


static func v2(from: float) -> Vector2:
	return Vector2(from, from)


# convert a string to a usable type
static func toexp(string: String) -> Variant:
	if string == "true": return true
	elif string == "false": return false
	elif string.is_valid_int(): return int(string)
	elif string.is_valid_float(): return float(string)
	return null


# weighted random function i found online for python
static func weighted_random(items: Array, weights: Array) -> Variant:
	if items.size() != weights.size():
		printerr("items and weights not equivalent in size.")
		return null
	if items.is_empty() or weights.is_empty():
		printerr("items and/or weights empty.")
		return null
	var cum_weigths := []
	var sum := 0
	for i in weights:
		sum += i
		cum_weigths.append(sum)
	var rand := (randi() % sum) + 1
	var index := cum_weigths.bsearch(rand)
	return items[index]


# put children of a node in a dictionary
static func child_dict(node: Node) -> Dictionary:
	var dict := {}
	for i in node.get_children():
		dict[i.name.to_snake_case()] = i
	return dict


static func but(a: bool, b: bool) -> bool:
	return (not a) and b


