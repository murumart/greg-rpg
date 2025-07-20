extends Node2D

const UIType := preload("res://scenes/rooms/store/restroom/scr_gambling_ui.gd")

const CLOWN_TEXTURE := preload("res://sprites/characters/overworld/spr_clown_overworld.png")
const KEY_STALL_OCCUPIERS := &"restroom_stall_occupiers"
const OCCUPIERS := 4

@onready var people: Node2D = $People
@onready var gambling_ui: UIType = $GamblingUI

var stall_occupiers: Array[StallOccupier] = []


func _ready() -> void:
	for i in $Interactions.get_children().size():
		$Interactions.get_child(i).interacted.connect(_stall_interacted.bind(i))

	_load_occupiers()
	_display_occupiers()

	remove_child(gambling_ui)
	SOL.add_ui_child(gambling_ui)


func _load_occupiers() -> void:
	var dat_occs: Array = DAT.get_data(KEY_STALL_OCCUPIERS, [])
	#print(dat_occs)
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
			# sprite with region and townspeople texture
			people.get_child(i).show()
			people.get_child(i).region_rect.position = occ.tp_region_position * 16
		elif occ.type == StallOccupier.Type.CLOWN:
			people.get_child(i).show()
			people.get_child(i).texture = CLOWN_TEXTURE
		i += 1


func _stall_interacted(which: int) -> void:
	var occ := stall_occupiers[which]
	print(occ)
	var sound := SND.play_sound(preload("res://sounds/door_knock.ogg"),
			{"return": true, "bus": "ECHO"})
	DAT.capture_player("door_knock")
	await sound.finished
	DAT.free_player("door_knock")
	if occ.type == StallOccupier.Type.TOWNSPERSON:
		var dial_id := (&"restroom_" + str(int(occ.tp_region_position.x))
				+ "_" + str(int(occ.tp_region_position.y))) as StringName
		if not SOL.dialogue_exists(dial_id):
			dial_id = &"restroom_default"
		SOL.dialogue(dial_id)
	elif occ.type == StallOccupier.Type.CLOWN:
		var last_gample: int = DAT.get_data("last_gample_second", -9999)
		var diff := DAT.seconds - last_gample
		if diff < 3600:
			SOL.dialogue_box.dial_concat("restroom_clown", 2, [snapped(60.0 - diff / 60.0, 0.1)])
			DAT.set_data("restroom_clown_thing", 2)
		else:
			DAT.set_data("restroom_clown_thing", 1 if DAT.get_data("restroom_clown_thing", 0) else 0)
		gambling_ui.reset()
		var buy_cost := 65
		SOL.dialogue_box.dial_concat("restroom_clown", 7, [buy_cost])
		SOL.dialogue("restroom_clown")
		await SOL.dialogue_closed
		if SOL.dialogue_choice == &"yes":
			if buy_cost > DAT.get_data("silver", 0):
				SOL.dialogue("restroom_clown_littlemoney")
				return
			SOL.dialogue("restroom_clown_gamble")
			await SOL.dialogue_closed
			DAT.incri("silver", -buy_cost)
			DAT.capture_player("gambling")
			gambling_ui.display()
			gambling_ui.finished.connect(func():
				gambling_ui.hide()
				gambling_ui.reset()
				DAT.free_player("gambling")
				DAT.set_data("last_gample_second", DAT.seconds)
			)


func _create_occupier() -> StallOccupier:
	var so := StallOccupier.new()
	so.start_second = DAT.seconds
	so.end_second = so.start_second + int(randfn(200, 150))

	if randf() < 0.2:
		so.type = StallOccupier.Type.TOWNSPERSON
		so.tp_region_position = _get_random_tp_position()
	# TODO add clown
	elif not have_occupier_of_type(StallOccupier.Type.CLOWN):
		so.type = StallOccupier.Type.CLOWN

	return so


func _save_me() -> void:
	DAT.set_data(KEY_STALL_OCCUPIERS,
			stall_occupiers.map(func(a: StallOccupier) -> Dictionary: return a.serialise()))


func have_occupier_of_type(type: StallOccupier.Type) -> bool:
	return stall_occupiers.any(
		func(a: StallOccupier) -> bool:
			return is_instance_valid(a) and a.type == type
	)


func _get_random_tp_position() -> Vector2:
	var reg_pos := Vector2.ZERO
	for i in 30:
		reg_pos = Vector2(randi_range(0, 3), randi_range(0, 3))
		if stall_occupiers.any(
			func(a: StallOccupier) -> bool:
				return is_instance_valid(a) and a.tp_region_position == reg_pos
		):
			continue
		break
	return reg_pos



class StallOccupier:

	enum Type {EMPTY, TOWNSPERSON, CLOWN}

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


	func _to_string() -> String:
		return Type.find_key(type) + "(" + str(start_second, ", ", end_second) + ")"
