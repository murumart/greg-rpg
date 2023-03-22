extends Resource
class_name BattlePayload

enum Types {ATTACK, SPIRIT, ITEM}
var type := Types.ATTACK

@export_group("Resources")
@export var health : float
@export var health_percent := 0.0
@export var max_health_percent := 0.0
@export var pierce_defense := 0.0

@export var magic : float
@export var magic_percent: float
@export var max_magic_percent: float

@export_group("Effects")
@export var attack_increase: float
@export var attack_increase_time: int
@export var defense_increase: float
@export var defense_increase_time: int
@export var speed_increase: float
@export var speed_increase_time: int
@export var confusion_time: int
@export var coughing_level: int
@export var coughing_time: int
@export var poison_level: int
@export var poison_time: int

@export_group("Other")
@export var summon_enemy := ""
@export var animation_on_receive := ""
var equip_as_weapon := false
var equip_as_armour := false
@export var reveal_enemy_info := false

var sender : BattleActor


func _init(_options := {}) -> void:
	pass


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


func set_confusion(time: int) -> BattlePayload:
	confusion_time = time
	return self


func set_coughing(amount: int, time: int) -> BattlePayload:
	coughing_level = amount
	coughing_time = time
	return self


func set_poison(amount: int, time: int) -> BattlePayload:
	poison_level = amount
	poison_time = time
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


func set_defense_pierce(x: float) -> BattlePayload:
	pierce_defense = x
	return self


func set_animation_on_receive(x: String) -> BattlePayload:
	animation_on_receive = x
	return self


func set_summon_enemy(x: String) -> BattlePayload:
	summon_enemy = x
	return self
