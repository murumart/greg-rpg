class_name Elements extends Node

# generating and storing chemical elements here
# do NOT show ANY of this to ANY of my chemistry teachers

enum Effects {SAFE, HEALTHY, POISONOUS, HARMFUL}

const ELEMENT_AMOUNT := 54
const PERIOD_LENGTHS := [2, 8, 8, 18, 18, 32, 32]
const CURVES: Array[Curve] = [preload("res://scenes/chemistry/harmful_curve.tres"), preload("res://scenes/chemistry/healthy_curve.tres"), preload("res://scenes/chemistry/poison_curve.tres")]
enum {HARM_CURVE, HEALTH_CURVE, POISON_CURVE}

var element_names := PackedStringArray()
var element_abbrs := PackedStringArray()
var element_masses := PackedFloat32Array()
var element_colours := PackedColorArray()
var element_effects := PackedInt32Array()
var periods: Array[PackedInt32Array] = [[], [], [], [], [], [], []]
var solmass: float

var in_by_sym := {}

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = roundi(DAT.get_data("nr", 0.0) * 100)


func gen() -> void:
	gen_elements()
	
	solmass = element_masses[0] + element_masses[0] + element_masses[7]


# the period of the element
func get_period(index: int) -> int:
	var period := 0
	var counter := 0
	for i in index:
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1
	return period


# the valence shell of the element
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


# the group of the element.
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


func has_d_valence(index: int) -> bool:
	return index in range(2, 12)


func get_element(index: int) -> Element:
	var el := Element.new()
	el.protons = index + 1
	el.name = element_names[index]
	el.mass = element_masses[index]
	el.symbol = element_abbrs[index]
	el.valence = get_valence(index)
	el.period = get_period(index)
	el.group = get_group(index)
	el.effect = element_effects[index] as Effects
	return el


func gen_elements() -> void:
	var counter := 0
	var period := 0
	# only this many elements. any more i'd have to deal with lanthanoids and s
	for e in ELEMENT_AMOUNT:
		var index := e + 1
		
		var ename := random_element_name(e)
		element_names.append(ename)
		element_abbrs.append(gen_element_symbol(ename))
		element_masses.append(snappedf((index) * 2 + rng.randf() * sqrt(index), 0.01))
		periods[period].append(e)
		in_by_sym[element_abbrs[e]] = e
		
		var effect: Effects = Effects.SAFE
		var rand := rng.randf()
		var sample := e / float(ELEMENT_AMOUNT)
		if rand < CURVES[POISON_CURVE].sample_baked(sample):
			effect = Effects.POISONOUS
		elif rand < CURVES[HARM_CURVE].sample_baked(sample):
			effect = Effects.HARMFUL
		elif rand < CURVES[HEALTH_CURVE].sample_baked(sample):
			effect = Effects.HEALTHY
		element_effects.append(effect)
		
		var color := Color(rng.randf(), rng.randf(), rng.randf())
		color = color.lightened((5 - period) * 0.1)
		element_colours.append(color)
		
		if counter >= PERIOD_LENGTHS[period] - 1:
			period += 1
			counter = 0
		else: counter += 1


func random_element_name(index: int) -> String:
	var vowels := ["a", "e", "i", "o", "u"]
	var plosives := ["ch", "p", "t", "g", "b", "d", "f"]
	var consonants := ["m", "n", "l", "s", "r", "z", "m", "n"]
	var end := ""
	var ends := {16: "ine", 17: "on"}
	var gene := func():
		var n := ""
		var prd := get_period(index)
		for i in rng.randi_range(maxi(prd, 1), maxi(prd, 2)):
			if rng.randf() <= 0.33:
				n += consonants.pick_random() + vowels.pick_random()
			elif rng.randf() <= 0.66:
				n += plosives.pick_random() + vowels.pick_random()
			else:
				n += vowels.pick_random() + consonants.pick_random()
		end = ends.get(get_group(index),
			Math.weighted_random(["ium", "", "uth", "ygen"], [8, 1, 1, 1]))
		if n.right(1) in consonants or n.right(1) in plosives:
			n += end
		else:
			n += plosives.pick_random() + end
		return n
	var ename := ""
	for i in 10:
		ename = gene.call()
		var free_of_unwanted := true
		var dontwantthese := ["uu", "mm"]
		for n in dontwantthese:
			if ename.contains(n): free_of_unwanted = false
		if not ename in element_names and free_of_unwanted == true:
			break
	return ename


func gen_element_symbol(ename: String) -> String:
	var symbol := ename[0]
	if not symbol in element_abbrs and rng.randf() <= 0.8:
		return symbol
	for j in ename.right(ename.length() - 1):
		var temp := symbol + j
		if not temp in element_abbrs:
			return temp
	printerr("not enough symbols for ", ename)
	return symbol


# all elements in a nice formatted string
func table_string() -> String:
	var text := ""
	var previous_pd := 0
	var previous_gp := 0
	for i in ELEMENT_AMOUNT:
		var pd := get_period(i)
		var gp := get_group(i)
		var sym := element_abbrs[i]
		var gp_diff := gp - previous_gp
		if pd > previous_pd:
			text += "\n"
		if gp_diff > 2:
			text += "   ".repeat(gp_diff - 1)
		text += (sym + " " if sym.length() > 1 else sym + "  ")
		previous_pd = pd
		previous_gp = gp
	
	return text


func is_more_active(a: int, b: int) -> bool:
	return a < b


class Element extends RefCounted:
	var protons: int
	var name: String
	var symbol: String
	var mass: float
	var period: int
	var group: int
	var valence: int
	var effect: Elements.Effects
	
	
	func _to_string() -> String:
		return "protons: %s
name: %s
symbol: %s
mass: %s
period: %s
group: %s
valence: %s
effect: %s
" % [protons, name, symbol, mass, period, group, valence, Elements.Effects.find_key(effect)]
