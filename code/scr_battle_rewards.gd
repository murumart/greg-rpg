class_name BattleRewards extends Resource

signal granted

enum Types {SILVER, ITEM, SPIRIT, EXP}

@export var rewards : Array[Reward] = []


func grant(speak := true) -> void:
	var silver_pool : int = 0
	var spirit_pool : Array[String] = []
	var item_pool : Array[String] = []
	var exp_pool : int = 0
	for reward in rewards:
		var prp := reward.property
		if not prp.length(): continue
		var prop = process_property(prp)
		match reward.type:
			Types.SILVER:
				if randf() <= reward.chance:
					silver_pool += prop
			Types.ITEM:
				if randf() <= reward.chance:
					item_pool.append(prop)
			Types.SPIRIT:
				if randf() <= reward.chance:
					spirit_pool.append(prop)
			Types.EXP:
				if randf() <= reward.chance:
					exp_pool += prop
	if silver_pool:
		DAT.grant_silver(silver_pool, speak)
	if exp_pool:
		for c in DAT.get_data("party", ["greg"]):
			DAT.get_character(c).add_experience(exp_pool, speak)
	for i in item_pool:
		DAT.grant_item(i, 0, speak)
	for i in spirit_pool:
		if not DAT.get_character("greg").has_spirit(i):
			DAT.grant_spirit(i, 0, speak)
	print("rewards granted :)")
	granted.emit()


func process_property(prp: String) -> Variant:
	if prp.is_valid_float():
		return float(prp)
	elif prp.begins_with("range "):
		prp = prp.trim_prefix("range ")
		var split := prp.split(",")
		if split.size() < 2:
			push_error("invalid reward property")
			return 0
		var range_0 := float(split[0])
		var range_1 := float(split[1])
		return float(roundi(randf_range(range_0, range_1)))
	elif prp in DAT.item_dict.keys():
		return prp
	elif prp in DAT.spirit_dict.keys():
		return prp
	push_error("invalid reward property")
	return 0
