class_name RoomVisitedPredicate extends Predicate

@export var room_key: StringName


func _internal_check() -> String:
	assert(DIR.room_exists(room_key))
	var rooms: Array = DAT.get_data("visited_rooms", [])
	if room_key not in rooms:
		return fail_string
	return SUCCESS
