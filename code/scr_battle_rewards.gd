class_name BattleRewards extends Resource

# rewards system resource for battles and minigames and such

signal granted

enum Types {SILVER, ITEM, SPIRIT, EXP}

@export var rewards: Array[Reward] = []


func add(reward: Reward):
	rewards.append(reward)


func valid() -> bool:
	return rewards.size() > 0


func grant(speak := true) -> void:
	var silver_pool: int = 0
	var spirit_pool: Array[String] = []
	var item_pool: Array[String] = []
	var exp_pool: int = 0
	# interpret rewards' properties and store results in pools
	for reward in rewards:
		# unique rewards can only be gotten once
		# hopefully this string key is good enough for storing them
		if reward.unique:
			if not str(reward) in DAT.get_data("unique_rewards", []):
				DAT.appenda("unique_rewards", str(reward))
			else: continue
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
	# then go through the pools and give stuff. to the player
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
	if exp_pool < 1 and spirit_pool.is_empty() and item_pool.is_empty() and silver_pool < 1:
		SOL.dialogue("emptyreward")
	granted.emit()


# interpreting the string reward property of a reward
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
	elif prp in DAT.item_dict.keys() or prp in DAT.spirit_dict.keys():
		return prp
	push_error("invalid reward property")
	return 0
