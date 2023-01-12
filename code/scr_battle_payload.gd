extends Resource
class_name BattlePayload

enum Types {ATTACK, SPIRIT, ITEM}
var type := Types.ATTACK

@export var health : float
@export var health_percent := 0.0
@export var max_health_percent := 0.0
@export var pierce_defense := 0.0

@export var magic : float
@export var magic_percent: float
@export var max_magic_percent: float

@export var attack_increase: float
@export var attack_increase_time: int
@export var defense_increase: float
@export var defense_increase_time: int
@export var speed_increase: float
@export var speed_increase_time: int

var equip_as_weapon := false
var equip_as_armour := false

var sender : BattleActor


func _init(_options := {}) -> void:
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


func set_type(x: Types) -> BattlePayload:
	type = x
	return self


func set_health(x: float) -> BattlePayload:
	health = x
	return self


func set_health_percent(x: float) -> BattlePayload:
	health_percent = x
	return self


func set_max_health_percent(x: float) -> BattlePayload:
	max_health_percent = x
	return self


func set_magic(x: float) -> BattlePayload:
	magic = x
	return self


func set_magic_percent(x: float) -> BattlePayload:
	magic_percent = x
	return self


func set_max_magic_percent(x: float) -> BattlePayload:
	max_magic_percent = x
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


func set_armour(x: bool) -> BattlePayload:
	equip_as_armour = x
	return self


func set_weapon(x: bool) -> BattlePayload:
	equip_as_weapon = x
	return self

