extends Node2D

# chemistry lab scene
# please note that any "simulation" is awful and shitty and inaccurate
# listen to C418 - life changing moments seem minor in pictures (the album)

var solution : Array[Dictionary]
var species : Array[Species] = []
var spec_id := 0

var gravity := 9.8

@onready var solution_area : ColorRect = $SolutionRect
@onready var union_sound: AudioStreamPlayer = $Audio/UnionSound
@onready var replacement_sound: AudioStreamPlayer = $Audio/ReplacementSound
@onready var dissociate_sound: AudioStreamPlayer = $Audio/DissociateSound
@onready var evaporation_sound: AudioStreamPlayer = $Audio/EvaporationSound
@onready var bounce_sound: AudioStreamPlayer2D = $Audio/BounceSound

const COOK_TIME := 10
var cook := 0.0
var cooking_finished := false


func _ready() -> void:
	if ELM.element_names.is_empty():
		ELM.gen()
		for i in Elements.ELEMENT_AMOUNT:
			print(ELM.get_element(i))
			print(" ")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	solution = [
		{
			"struct": [14, 7, 0],
			"mol": 3.0
		},
		{
			"struct": [20, 7, 0],
			"mol": 3.0
		},
		{
			"struct": [30, 7, 0],
			"mol": 3.0
		},
	]
	for i in 6:
		solution.append({
			"struct": [14, 7, 0, 36],
			"mol": 3.0
		})
	germinate()
	


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


# not how it works in real life dear god not at all
func dissoc_reaction(s: Species) -> void:
	if s.struct.size() < 3: return
	var pos := s.position
	var split := clampi(randi() % s.struct.size(), 1, s.struct.size() - 1)
	var a := s.struct.slice(split)
	var b := s.struct.slice(0, split)
	a.append_array([0])
	b.append_array([0, 7])
	del(s)
	c(a, pos)
	c(b, pos)
	dissociate_sound.play()


# chemistry treachers weep
func replacement_reaction(s1: Species, s2: Species, pos : Vector2) -> void:
	if s1.struct.is_empty() or s2.struct.is_empty(): return
	var at : int = 0
	if s1.struct.size() > s2.struct.size():
		at = randi() % s2.struct.size()
	else:
		at = randi() % s1.struct.size()
	var a1 : int = s1.struct.pop_at(at)
	var a2 : int = s2.struct.pop_at(at)
	if a1 == a2:
		c([a1, a2], pos)
	else:
		s1.struct.insert(at, a2)
		s2.struct.insert(at, a1)
	s1.aspects()
	s2.aspects()
	replacement_sound.play()


func union_reaction(s1: Species, s2: Species, pos: Vector2) -> void:
	if s1.struct.is_empty() or s2.struct.is_empty(): return
	if not (0 in s1.struct and 7 in s1.struct and 0 in s2.struct): return
	s1.struct.erase(0)
	s2.struct.erase(0)
	s1.struct.erase(7)
	c([0, 0, 7], pos)
	var news := s1.struct.duplicate()
	news.append_array(s2.struct)
	c(news, pos)
	del(s1)
	del(s2)
	union_sound.play()


func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action("ui_accept"):
		dissoc_reaction(species.pick_random())


func _physics_process(delta: float) -> void:
	var clamp_zone_min := solution_area.position
	var clamp_zone_max : Vector2 = solution_area.position + solution_area.size
	var damp := 0.44
	var rand := 0.2
	var edgedef := 0.5
	if cook < COOK_TIME:
		for s in species:
			if s.struct.is_empty():
				del(s)
				return
			
			if species.size() > 80:
				if Engine.get_physics_frames() % 2 != 0: continue
			
			# damping
			s.move.y = move_toward(s.move.y, (s.mass - ELM.solmass) * 0.06, delta * 6)
			# delete stuff rising tot he top (it evepaorates away)
			if (s.mass < ELM.solmass or absf(s.mass - ELM.solmass) < 0.1) and randf() < 0.007:
				del(s)
				evaporation_sound.play()
			s.move.x = move_toward(s.move.x, 0.0, delta)
			
			# randomising
			s.move += Vector2(randf_range(-rand, rand), randf_range(-rand, rand))
			
			# collision with others
			if species.size() < 25:
				for ss in range(species.size()):
					if ss >= species.size(): continue
					var sp1 := species[ss]
					for zz in species.size():
						if zz == ss: continue
						if zz >= species.size(): continue
						var sp2 := species[zz]
						specs_collision(sp1, sp2)
			# if there's too many species simulated, do this instead
			# because this is faster
			# yeah
			else:
				for i in 200:
					specs_collision(species.pick_random(), species.pick_random())
			
			# dissoc checking
			if s.mass / 900.0 > randf() and randf() < 0.002 and species.size() < 40:
				dissoc_reaction(s)
			
			# edges collision
			if s.position.x - s.radius <= clamp_zone_min.x:
				s.move.x = edgedef -s.move.x * damp
				bounce_sound.play()
			if s.position.x + s.radius >= clamp_zone_max.x:
				s.move.x = -edgedef -s.move.x * damp
				bounce_sound.play()
			if s.position.y - s.radius <= clamp_zone_min.y:
				s.move.y += delta * 8
			if s.position.y + s.radius >= clamp_zone_max.y:
				s.move.y = -edgedef -s.move.y * damp
				bounce_sound.play()
			bounce_sound.position.x = s.position.x
			s.position = s.position.clamp(clamp_zone_min, clamp_zone_max)
			
			s.position += s.move
			
			# clicking debug stuff
			if Input.is_action_just_pressed("mouse_left"):
				var mpos := get_global_mouse_position()
				if mpos.distance_to(s.position) < s.radius:
					print(s)
		
		if randf() < 0.08:
			c([0, 7, 0], Vector2(randf_range(clamp_zone_min.x, clamp_zone_max.x),
			randf_range(clamp_zone_min.y, clamp_zone_max.y)))
		cook += delta
	else:
		if not cooking_finished:
			for i in species:
				if not i.is_water():
					print(i)
			cooking_finished = true
	queue_redraw()


func specs_collision(s1: Species, s2: Species) -> void:
	if s1 == s2: return
	var damp := 0.005
	if s1.position.distance_squared_to(s2.position) <= (s1.radius + s2.radius) ** 2:
		var mid := (s1.position + s2.position) / 2.0
		s1.move += (s1.position - s2.position) * damp * s2.mass/s1.mass
		s2.move += (s2.position - s1.position) * damp * s1.mass/s2.mass
		if randf() < 0.0025:
			replacement_reaction(s1, s2, mid)
		if randf() < 0.0025:
			union_reaction(s1, s2, mid)
		return


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
		if struct.is_empty():
			return
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
	
	
	func is_water() -> bool:
		return struct.size() == 3 and struct.count(0) == 2 and struct.has(7)
	
	
	func _to_string() -> String:
		return "%s: %s" % [id, struct]
