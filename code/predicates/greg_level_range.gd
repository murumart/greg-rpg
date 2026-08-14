class_name GregLevelRangePredicate extends Predicate

@export_range(1, 99, 1) var level_min: int
@export_range(1, 99, 1) var level_max: int


func _internal_check() -> String:
	assert(level_min <= level_max)
	var greg := ResMan.get_character("greg")
	if Math.inrange(greg.level, level_min, level_max):
		return SUCCESS
	return fail_string
