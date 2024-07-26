class_name DataUpdater extends RefCounted


static func needs_updating(data: Dictionary) -> bool:
	var version := data.get("version", SaveScreen.UNKNOWN_VERSION) as Vector3
	if version == SaveScreen.UNKNOWN_VERSION:
		return true
	var super_difference := DAT.VERSION.x - version.x as int
	var major_difference := DAT.VERSION.y - version.y as int
	var minor_difference := DAT.VERSION.z - version.z as int
	return super_difference > 0 or major_difference > 0 or minor_difference > 0


static func update_data(data: Dictionary) -> void:
	_fix_sprits_typo(data)
	_replace_you_sop(data)


static func _fix_sprits_typo(data: Dictionary) -> void:
	var greg := data.get("char_greg_save", {}) as Dictionary
	if not greg:
		return
	var uspirits: Array[String] = []
	uspirits.assign(greg.get("unused_sprits"))
	greg.erase("unused_sprits")
	print("fixing unused_sprits name typo")
	greg["unused_spirits"] = uspirits


static func _replace_you_sop(data: Dictionary) -> void:
	var bounty_done := data.get("fulfilled_bounty_broken_fishermen", false) as bool
	if not bounty_done:
		return
	var greg := data.get("char_greg_save", {}) as Dictionary
	if not greg:
		printerr("no greg save")
		return
	var uspirits: Array[String] = []
	uspirits.assign(greg.get("unused_spirits", []))
	var spirits: Array[String] = []
	spirits.assign(greg.get("spirits", []))
	if "splash_attack" in uspirits:
		print("replacing spash attack in unused spirits")
		uspirits.erase("splash_attack")
		uspirits.append("blue_carpet")
		greg["unused_spirits"] = uspirits
	if "splash_attack" in spirits:
		print("replacing spash attack in spirits")
		spirits.erase("splash_attack")
		spirits.append("blue_carpet")
		greg["spirits"] = spirits

