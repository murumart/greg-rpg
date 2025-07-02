class_name BattleRewards extends Resource

# rewards system resource for battles and minigames and such

signal granted

enum Types {SILVER, ITEM, SPIRIT, EXP, GLASS}

@export var rewards: Array[Reward] = []


func add(reward: Reward) -> void:
	rewards.append(reward)


func clear() -> void:
	rewards.clear()


func valid() -> bool:
	return rewards.size() > 0


func grant(speak := true) -> void:
	var silver_pool: int = 0
	var spirit_pool: Array[String] = []
	var item_pool: Array[String] = []
	var exp_pool: int = 0
	var glass_pool: int = 0
	# interpret rewards' properties and store results in pools
	for reward in rewards:
		if reward.unique_gotten():
			continue
		var prp := reward.property
		if not prp.length():
			continue
		var prop = process_property(prp)
		match reward.type:
			Types.SILVER:
				if randf() <= reward.chance:
					silver_pool += prop
			Types.ITEM:
				if randf() <= reward.chance:
					item_pool.append(prop)
					handle_uniqueness(reward)
			Types.SPIRIT:
				if randf() <= reward.chance:
					spirit_pool.append(prop)
					handle_uniqueness(reward)
			Types.EXP:
				if randf() <= reward.chance:
					exp_pool += prop
			Types.GLASS:
				if randf() <= reward.chance:
					glass_pool += prop
	# then go through the pools and give stuff. to the player
	if silver_pool:
		DAT.grant_silver(silver_pool, speak)
	if exp_pool:
		for c in DAT.get_data("party", ["greg"]):
			ResMan.get_character(c).add_experience(exp_pool, speak)
	for i in item_pool:
		DAT.grant_item(i, 0, speak)
	for i in spirit_pool:
		if not ResMan.get_character("greg").has_spirit(i):
			DAT.grant_spirit(i, 0, speak)
	if exp_pool < 1 and spirit_pool.is_empty() and item_pool.is_empty() and silver_pool < 1:
		SOL.dialogue("emptyreward")
	if glass_pool and DAT.get_data("forest_questing", null):
		(DAT.get_data("forest_questing") as ForestQuesting).grant_glass(glass_pool)
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
		return roundf(randf_range(range_0, range_1))
	elif prp in ResMan.items.keys() or prp in ResMan.spirits.keys():
		return prp
	push_error("invalid reward property")
	return 0


func _to_string() -> String:
	return "rewards: " + str(rewards)


func handle_uniqueness(reward: Reward) -> void:
	# unique rewards can only be gotten once
	# hopefully this string key is good enough for storing them
	if reward.unique:
		if not str(reward) in DAT.get_data("unique_rewards", []):
			DAT.appenda("unique_rewards", str(reward))
