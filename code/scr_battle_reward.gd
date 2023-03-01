class_name Reward extends Resource
	
@export var type : BattleRewards.Types
@export var property : String
@export_range(0.0, 1.0) var chance := 1.0


func _init() -> void:
	pass
