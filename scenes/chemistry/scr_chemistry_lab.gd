extends Node2D

# chemistry lab scene

var elements := Elements.new()

var solution : Array[Dictionary]


func _ready() -> void:
	SOL.vfx("isotoxin", SOL.SCREEN_SIZE / 16.0, {"silent": true})
	var el := 13
	print(elements.get_element(el).tostr())
	print(elements.get_valence(el))
	for i in elements.ELEMENT_AMOUNT:
		print(elements.get_element(i).tostr())
	print(elements.element_names)
	print(elements.table_string())
	
	var ethanol := c([ [5,  [0, 0, 0] ] ,  [5,  [0, 0] ] ,  [7, 0] ])
	print(ethanol.calculate_mass(ethanol.struct))


func _draw() -> void:
	pass


func c(arr : Array) -> Compound:
	return Compound.new(arr, elements)


class Compound extends Node2D:
	
	var struct : Array = []
	var mass : float
	
	var elements : Elements
	
	
	func _init(c: Array, el: Elements) -> void:
		struct = c
		elements = el
	
	
	# loop through all branches and add masses
	func calculate_mass(arr: Array) -> float:
		var sum := 0.0
		for a in arr:
			if a is String:
				sum += elements.in_by_sym.get(a, 12837)
			elif a is int:
				sum += elements.element_masses[a]
			elif a is Array:
				sum += calculate_mass(a)
		return sum
	
	
	func _physics_process(delta: float) -> void:
		pass
	
	
	func _draw() -> void:
		pass
	

