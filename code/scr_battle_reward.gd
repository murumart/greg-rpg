class_name Reward extends Resource

# stores one reward, interpreted by BattleRewards

@export var type : BattleRewards.Types
# reward is stored in a string and interpreted
@export var property : String
@export_range(0.0, 1.0) var chance := 1.0


func _init() -> void:
	pass
