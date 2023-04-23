class_name Elements extends RefCounted

var used_element_names := []
var used_element_symbols := []
const ELEMENT_AMOUNT := 54
const PERIOD_LENGTHS := [2, 8, 8, 18, 18, 32, 32]

var element_names := PackedStringArray()
var element_abbrs := PackedStringArray()
var element_masses := PackedFloat32Array()
var periods : Array[PackedInt32Array] = [[], [], [], [], [], [], []]

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = roundi(DAT.get_data("nr", 0.0) * 100)
	gen_elements()


func get_period(index: int) -> int:
	var period := 0
	var counter := 0
	for i in index:
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1
	return period


func get_valence(index: int) -> int:
	var period := 0
	var counter := 0
	for i in index:
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1
	if counter <= 11:
		return counter + 1
	return counter - 9


func get_group(index: int) -> int:
	var period := 0
	var counter := 0
	for i in index:
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1
	if period >= 3:
		return counter
	if index == 1:
		return 17
	return counter + 10 if counter > 1 else counter


func get_element(index: int) -> Element:
	var el := Element.new()
	el.name = element_names[index]
	el.mass = element_masses[index]
	el.symbol = element_abbrs[index]
	return el


func gen_elements() -> void:
	var counter := 0
	var period := 0
	for e in ELEMENT_AMOUNT:
		var index := e + 1
		
		var name := random_element_name(e)
		element_names.append(name)
		element_abbrs.append(gen_element_symbol(name))
		element_masses.append(snappedf((index) * 2 + rng.randf() * sqrt(index), 0.01))
		periods[period].append(e)
		
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1


func random_element_name(index: int) -> String:
	var name := ""
	var vowels := ["a", "e", "i", "o", "u"]
	var plosives := ["ch", "p", "t", "g", "b", "d", "f"]
	var consonants := ["m", "n", "l", "s", "r", "z", "m", "n"]
	var end := ""
	var ends := {16: "ine", 17: "on"}
	var gen := func generation():
		var n := ""
		var prd := get_period(index)
		for i in randi_range(maxi(prd, 1), maxi(prd, 2)):
			if rng.randf() <= 0.33:
				n += consonants.pick_random() + vowels.pick_random()
			elif rng.randf() <= 0.66:
				n += plosives.pick_random() + vowels.pick_random()
			else:
				n += vowels.pick_random() + consonants.pick_random()
		end = ends.get(get_group(index), "ium")
		if n.right(1) in consonants or n.right(1) in plosives:
			n += end
		else:
			n += plosives.pick_random() + end
		return n
	for i in 10:
		name = gen.call()
		if not name in used_element_names:
			break
	used_element_names.append(name)
	return name


func gen_element_symbol(name: String) -> String:
	var symbol := ""
	for i in 10:
		symbol = name[0] + (name[rng.randi() % name.length()] if randf() < 0.88 else "")
		if not symbol in used_element_symbols and ((not symbol.left(1) == symbol.right(1)) if symbol.length() > 1 else true):
			break
	return symbol


class Element extends RefCounted:
	var name : String
	var symbol : String
	var mass : float
