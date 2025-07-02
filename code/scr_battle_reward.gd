class_name Reward extends Resource

# stores one reward, interpreted by BattleRewards

@export var type: BattleRewards.Types
# reward is stored in a string and interpreted
@export var property: String
@export_range(0.0, 1.0) var chance := 1.0
@export var unique := false


func _init(opt := {}) -> void:
	if opt.get("type"):
		type = opt.type
	if opt.get("property"):
		property = opt.property
	if opt.get("chance"):
		chance = opt.get(chance)
	if opt.get("unique"):
		unique = opt.get(unique)
	pass


func unique_gotten() -> bool:
	if unique:
		if str(self) in DAT.get_data("unique_rewards", []):
			return true
	return false


func _to_string() -> String:
	return "reward_%s_%s" % [BattleRewards.Types.find_key(type), property]
