extends Resource
class_name BattlePayload

# resource that stores attack info in battles
# interpreted and exchanged by battle actors

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
@export var defense_increase: float
@export var speed_increase: float
@export var effects : Array[StatusEffect] = []

@export_group("Other")
@export var delay := 0.0
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


func set_attack_increase(amount: float) -> BattlePayload:
	attack_increase = amount
	return self


func set_defense_increase(amount: float) -> BattlePayload:
	defense_increase = amount
	return self


func set_speed_increase(amount: float) -> BattlePayload:
	speed_increase = amount
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

