extends RefCounted
class_name BattlePayload

var health : float
var magic : float

var attack_increase: float
var attack_increase_time: int
var defense_increase: float
var defense_increase_time: int
var speed_increase: float
var speed_increase_time: int

var sender : BattleActor


func _init(options := {}) -> void:
	pass
#	health = options.get("health", 0.0)
#	magic = options.get("magic", 0.0)
#	attack_increase = options.get("attack_increase", 0.0)
#	attack_increase_time = options.get("attack_increase_time", 0)
#	defense_increase = options.get("defense_increase", 0.0)
#	defense_increase_time = options.get("defense_increase_time", 0)
#	speed_increase = options.get("speed_increase", 0.0)
#	speed_increase_time = options.get("speed_increase_time", 0)
#	sender = options.get("sender", null)


func set_health(x: float) -> BattlePayload:
	health = x
	return self


func set_magic(x: float) -> BattlePayload:
	magic = x
	return self


func set_attack_increase(amount: float, time: int) -> BattlePayload:
	attack_increase = amount
	attack_increase_time = time
	return self


func set_defense_increase(amount: float, time: int) -> BattlePayload:
	defense_increase = amount
	defense_increase_time = time
	return self


func set_speed_increase(amount: float, time: int) -> BattlePayload:
	speed_increase = amount
	speed_increase_time = time
	return self

func set_sender(x: BattleActor) -> BattlePayload:
	sender = x
	return self
