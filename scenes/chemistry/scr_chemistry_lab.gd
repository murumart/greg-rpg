extends Node2D

# chemistry lab scene
# please note that any "simulation" is awful and shitty and inaccurate
# listen to C418 - life changing moments seem minor in pictures (the album)

var solution : Array[Dictionary]
var species : Array[Species] = []
var spec_id := 0

var gravity := 9.8

@onready var solution_area : ColorRect = $SolutionRect


func _ready() -> void:
	if ELM.element_names.is_empty():
		ELM.gen()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	solution = [
		{
			"struct": [14, [7, 0]],
			"mol": 3.0
		},
		{
			"struct": [20, [7, 0]],
			"mol": 3.0
		},
		{
			"struct": [30, [7, 0]],
			"mol": 3.0
		},
	]
	for i in 6:
		solution.append({
			"struct": [14, [7, 0]],
			"mol": 3.0
		})
	germinate()
	
	var s := c([[15, [[7], [[7], [[[[[[[[[7, 0]]]]], [7, 0]]]]]]]]])
	print(s.find_chain([7, 0]))
	print(s.get_chain(s.find_chain([7, 0]).get("index")))
	s.set_chain(s.find_chain([7, 0]).index, [8, 0])
	print(s.get_chain([0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]))



func germinate() -> void:
	for i in solution:
		var st : Array = i.get("struct", [0])
		c(st)


func c(arr : Array, pos := Vector2()) -> Species:
	var s := Species.new(arr, pos)
	s.move.x += randf_range(-5, 5)
	s.id = spec_id
	spec_id += 1
	species.append(s)
	return s


func del(d: Species) -> void:
	if d in species:
		species.erase(d)


func react(c1: Species, c2: Species) -> void:
	pass


# not how it works in real life dear god not at all
func dissoc_reaction(s: Species) -> void:
	var suc := s.struct.duplicate(true)
	var split := mini(randi() % suc.size() + 1, suc.size() - 1)
	var a := suc.slice(0, split, 1, true)
	var b := suc.slice(split, suc.size(), 1, true)
	var pos := s.position
	a.push_front([0])
	b.push_front([7, 0])
	print(a)
	print(b)
	del(s)
	c(a, pos)
	c(b, pos)


# chemistry treachers weep
# todo: make not freeze the game completely
func replacement_reaction(s1: Species, s2: Species, pos : Vector2) -> void:
	var o : int =  mini(randi() % s1.struct.size() + 1, s1.struct.size() - 1)
	var p : int = mini(randi() % s2.struct.size() + 1, s2.struct.size() - 1)
	var q1 := s1.struct.slice(0, o, 1, true) if s1.struct.size() > 2 else s1.struct
	var q2 := s1.struct.slice(o, s1.struct.size(), 1, true) if s1.struct.size() > 2 else s1.struct
	var w1 := s2.struct.slice(0, p, 1, true) if s2.struct.size() > 2 else s2.struct
	var w2 := s2.struct.slice(o, s2.struct.size(), 1, true) if s2.struct.size() > 2 else s2.struct
	var m := []
	m.append_array(q1)
	m.append_array(w1)
	var n := []
	n.append_array(q2)
	n.append_array(w2)
	del(s1)
	del(s2)
	c(m, pos)
	c(n, pos)


func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action("ui_accept"):
		dissoc_reaction(species.pick_random())


func _physics_process(delta: float) -> void:
	var clamp_zone_min := solution_area.position
	var clamp_zone_max : Vector2 = solution_area.position + solution_area.size
	var damp := 0.44
	var rand := 0.2
	var edgedef := 0.5
	for s in species:
		
		if species.size() > 80:
			if Engine.get_physics_frames() % 2 != 0: continue
		
		# damping
		s.move.y = move_toward(s.move.y, (s.mass - ELM.solmass) * 0.06, delta * 6)
		s.move.x = move_toward(s.move.x, 0.0, delta)
		
		# randomising
		s.move += Vector2(randf_range(-rand, rand), randf_range(-rand, rand))
		
		# collision with others
		var coll := false
		if species.size() < 25:
			for ss in range(species.size()):
				var sp1 := species[ss]
				for zz in species.size():
					if zz == ss: continue
					var sp2 := species[zz]
					coll = specs_collision(sp1, sp2)
		# if there's too many species simulated, do this instead
		# because this is faster
		# yeah
		else:
			for i in 200:
				coll = specs_collision(species.pick_random(), species.pick_random())
		
		#
		if not coll and randf() < 0.0002 and species.size() < 25:
			dissoc_reaction(species.pick_random())
		
		# edges collision
		if s.position.x - s.radius <= clamp_zone_min.x:
			s.move.x = edgedef -s.move.x * damp
		if s.position.x + s.radius >= clamp_zone_max.x:
			s.move.x = -edgedef -s.move.x * damp
		if s.position.y - s.radius <= clamp_zone_min.y:
			s.move.y += delta * 8
			#s.move.y = edgedef -s.move.y * damp
		if s.position.y + s.radius >= clamp_zone_max.y:
			s.move.y = -edgedef -s.move.y * damp
		s.position = s.position.clamp(clamp_zone_min, clamp_zone_max)
		
		s.position += s.move
	
	queue_redraw()


func specs_collision(s1: Species, s2: Species) -> bool:
	if s1 == s2: return false
	var damp := 0.005
	if s1.position.distance_squared_to(s2.position) <= (s1.radius + s2.radius) ** 2:
		var mid := (s1.position + s2.position) / 2.0
		s1.move += (s1.position - s2.position) * damp * s2.mass/s1.mass
		s2.move += (s2.position - s1.position) * damp * s1.mass/s2.mass
		if randf() < 0.25:
			replacement_reaction(s1, s2, mid)
		return true
	return false


func _draw() -> void:
	for s in species:
		draw_circle(s.position, s.radius, s.color)


class Species extends RefCounted:
	
	var id : int
	var struct := []
	var mass : float
	var radius : float
	var color := Color()
	var move := Vector2()
	var position := Vector2()
	
	
	func _init(arr: Array, pos: Vector2 = Vector2(0, 0)) -> void:
		struct = arr
		position = pos
		aspects()
	
	
	func aspects() -> void:
		radius = calculate_radius(struct)
		mass = calculate_mass(struct)
		color = calculate_colour(struct)
	
	
	# loop through all branches and add masses
	func calculate_mass(arr: Array) -> float:
		var sum := 0.0
		for a in arr:
			if a is String:
				sum += ELM.in_by_sym.get(a, 12837)
			elif a is int:
				sum += ELM.element_masses[a]
			elif a is Array:
				sum += calculate_mass(a)
		return sum


	func calculate_radius(arr: Array) -> float:
		var sum := 0.0
		for a in arr:
			if a is String:
				sum += ELM.in_by_sym.get(a, 12837)
			elif a is int:
				sum += ELM.element_masses[a] * 0.05
			elif a is Array:
				sum += calculate_radius(a)
		return snappedf(maxf(sum, 0.5), 0.1)


	func calculate_colour(arr: Array) -> Color:
		var col : Color
		var cols := []
		for a in arr:
			if a is int:
				cols.append(ELM.element_colours[a])
			elif a is Array:
				cols.append(calculate_colour(a))
		col = cols[0]
		for i in cols:
			col = col.lerp(i, 0.1)
		return col
	
	
	func find_chain(what: Variant, inwhat: Array = struct) -> Dictionary:
		var index := []
		for n in inwhat:
			# if we find what we're looking for
			if typeof(what) == typeof(n) and what == n:
				index.append(inwhat.find(n))
				return {"found": true, "index": index}
			# otherwise enter array and search it as well
			elif n is Array:
				var rec := find_chain(what, n)
				if rec.get("found", false):
					index.append(inwhat.find(n))
					index.append_array(rec.get("index"))
					return {"found": true, "index": index}
		return {"found": false}
	
	
	func get_chain(index: Array, inwhat: Array = struct) -> Variant:
		var i : int = index.pop_front()
		if not index.is_empty():
			return get_chain(index, inwhat[i])
		else:
			return inwhat[i]
		return null
	
	
	func set_chain(index: Array, towhat: Variant, inwhat: Array = struct) -> void:
		var i : int = index.pop_front()
		if not index.is_empty():
			set_chain(index, towhat, inwhat[i])
		else:
			inwhat[i] = towhat
	
	
	func _to_string() -> String:
		return "%s, %s" % [position, radius]
