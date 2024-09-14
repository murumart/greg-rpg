extends Node2D

const KEY_STALL_OCCUPIERS := &"restroom_stall_occupiers"
const OCCUPIERS := 4

@onready var people: Node2D = $People

var stall_occupiers: Array[StallOccupier] = []


func _ready() -> void:
	for i in $Interactions.get_children().size():
		$Interactions.get_child(i).on_interact.connect(_stall_interacted.bind(i))

	_load_occupiers()
	_display_occupiers()


func _load_occupiers() -> void:
	var dat_occs: Array = DAT.get_data(KEY_STALL_OCCUPIERS, [])
	print(dat_occs)
	dat_occs.resize(OCCUPIERS)
	stall_occupiers.resize(OCCUPIERS)
	for i in OCCUPIERS:
		var occ := (StallOccupier.deserialise(dat_occs[i])
				if dat_occs[i]
				else _create_occupier())
		if occ.end_second < DAT.seconds:
			occ = _create_occupier()

		stall_occupiers[i] = occ


func _display_occupiers() -> void:
	var i := 0
	for occ in stall_occupiers:
		if occ.type == StallOccupier.Type.TOWNSPERSON:
			people.get_child(i).show()
			people.get_child(i).region_rect.position = occ.tp_region_position * 16

		i += 1


func _stall_interacted(which: int) -> void:
	print(which)


func _create_occupier() -> StallOccupier:
	var so := StallOccupier.new()
	so.start_second = DAT.seconds
	so.end_second = so.start_second + int(randfn(200, 150))

	if randf() < 0.2:
		so.type = StallOccupier.Type.TOWNSPERSON
		so.tp_region_position = Vector2(randi_range(0, 3), randi_range(0, 3))

	return so


func _save_me() -> void:
	DAT.set_data(KEY_STALL_OCCUPIERS,
			stall_occupiers.map(func(a: StallOccupier) -> Dictionary: return a.serialise()))


class StallOccupier:

	enum Type {EMPTY, TOWNSPERSON}

	var type := Type.EMPTY
	var tp_region_position := Vector2.ZERO
	var start_second: int
	var end_second: int


	static func deserialise(dict: Dictionary) -> StallOccupier:
		var so := StallOccupier.new()
		so.type = dict.type as Type
		so.start_second = dict.start_second
		so.end_second = dict.end_second
		so.tp_region_position = dict.get("tp_region_position", Vector2.ZERO)
		return so


	func serialise() -> Dictionary:
		var dict := {
			"start_second": start_second,
			"end_second": end_second,
			"type": int(type)
		}
		if type == Type.TOWNSPERSON:
			dict["tp_region_position"] = tp_region_position
		return dict
