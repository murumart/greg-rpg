extends Resource
class_name BattlePayload

# resource that stores attack info in battles
# interpreted and exchanged by battle actors

const MAX_BOUNCES = 3

enum Types {ATTACK, SPIRIT, ITEM, EFFECT}
var type := Types.ATTACK

const FIELDS := [
	&"health", &"health_percent", &"max_health_percent",
	&"pierce_defense", &"steal_health",
	&"magic", &"magic_percent", &"max_magic_percent",
	&"attack_increase", &"defense_increase", &"speed_increase",
	&"gender", &"effects",
	&"delay", &"summon_enemy", &"animation_on_receive"
]

@export_group("Resources")
@export var health: float
@export var health_percent := 0.0
@export var max_health_percent := 0.0
@export_range(0.0, 1.0) var pierce_defense := 0.0
@export_range(0.0, 1.0) var steal_health := 0.0

@export var magic: float
@export var magic_percent: float
@export var max_magic_percent: float
@export_range(0.0, 1.0) var steal_magic := 0.0

@export_group("Effects")
@export var attack_increase: float
@export var defense_increase: float
@export var speed_increase: float
@export_enum(
	"None", "Electric",
	"Sopping", "Burning",
	"Ghost", "Brain", "Vast"
	) var gender: int
@export var effects: Array[StatusEffect] = []

@export_group("Other")
@export var delay := 0.0
@export var summon_enemy := ""
@export var max_enemies := 6
@export var animation_on_receive := ""
var equip_as_weapon := false
var equip_as_armour := false
var critical := false
@export var message_user := &""
@export var meta := {}

var sender: BattleActor
var bounces := 0


func _init(_options := {}) -> void:
	pass


func get_effect_description() -> String:
	var text := ""
	if health or health_percent or max_health_percent:
		var health_change := ""
		var harm := health < 0 or health_percent < 0 or max_health_percent < 0
		if harm:
			health_change += "damage: "
		else:
			health_change += "health: "
		if health:
			health_change += str(int(abs(health))) + " "
		if health_percent:
			if health: health_change += "+"
			health_change += str(int(absf(health_percent))) + "% hp "
		if max_health_percent:
			if health_percent: health_change += "+"
			health_change += str(int(absf(max_health_percent))) + "% max hp "
		var colour := "[color=#880000]%s[/color]" if harm else "[color=#008800]%s[/color]"
		health_change = colour % health_change
		text += health_change + "\n"
	if steal_health:
		text += "[color=#448800]%s[/color]\n" % (
			("steal %s" % int(steal_health * 100)) + "% dmg as hp")
	if magic or magic_percent or max_magic_percent:
		var magic_change := ""
		var harm := magic < 0 or magic_percent < 0 or max_magic_percent < 0
		if harm: magic_change += "-magic: "
		else: magic_change += "+magic: "
		if magic: magic_change += str(int(absf(magic))) + " "
		if magic_percent:
			if magic: magic_change += "+"
			magic_change += str(int(absf(magic_percent))) + "% sp "
		if max_magic_percent:
			if magic_percent: magic_change += "+"
			magic_change += str(int(absf(max_magic_percent))) + "% max sp "
		var colour := "[color=#880088]%s[/color]" if harm else "[color=#008888]%s[/color]"
		magic_change = colour % magic_change
		text += magic_change + "\n"
	if steal_magic:
		text += "[color=#004488]%s[/color]\n" % (
			("steal %s" % int(steal_magic * 100)) + "% dmg as sp")
	if attack_increase:
		var harm := attack_increase < 0
		var c := "[color=#884400]%s%s atk[/color]" if not harm else "[color=#880044]%s%s atk[/color]"
		text += c % [Math.sign_symbol(attack_increase), int(absf(attack_increase))] + "\n"
	if defense_increase:
		var harm := defense_increase < 0
		var c := "[color=#008822]%s%s def[/color]" if not harm else "[color=#884400]%s%s def[/color]"
		text += c % [Math.sign_symbol(defense_increase), int(absf(defense_increase))] + "\n"
	if speed_increase:
		var harm := speed_increase < 0
		var c := "[color=#888800]%s%s spd[/color]" if not harm else "[color=#884400]%s%s spd[/color]"
		text += c % [Math.sign_symbol(speed_increase), int(absf(speed_increase))] + "\n"
	for eff in effects:
		var fid := eff.name
		if eff.duration < -1:
			fid += "_immunity"
		var efftype := ResMan.get_effect(fid)
		var fname := efftype.name
		var efftxt := ""
		var curescriptions := {
			&"fire": "fire extinguished"
		}
		var effcolor := efftype.color.to_html()
		if eff.duration < -1:
			efftxt += ("[color=#%s]%s[/color]" % [effcolor, fname]) +\
			" for %s\n" % absi(eff.duration)
		elif eff.duration == -1:
			efftxt += "[color=#668866]%s[/color]\n" % (curescriptions.get(eff.name, "cures " + fname))
		elif eff.strength < 0:
			effcolor = efftype.color.darkened(0.2).to_html()
			efftxt += "[color=#%s]%s[/color]" % [effcolor,
			# the horrors
					(fname + ((" " + Math.sign_symbol(eff.strength) + str(
					int(absf(eff.strength))) + " ") if eff.strength != 1
					else " ") + "for %s\n" % eff.duration)
				]
		else:
			efftxt += ("[color=#%s]%s[/color]" % [effcolor,
					(fname + ((" " + Math.sign_symbol(eff.strength) + str(
					int(absf(eff.strength))) + " ")  if eff.strength != 1 else " "))
				] + "for %s\n" % eff.duration)
		text += efftxt
	if gender:
		text += "[color=#444444]type:[/color] [color=#%s]" % Genders.COLOURS[gender].to_html(false)
		text += Genders.NAMES[gender]
		text += "[/color]\n"
	return text


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


func set_effects(x: Array[StatusEffect]) -> BattlePayload:
	effects = x
	return self


func set_gender(x: int) -> BattlePayload:
	gender = x
	return self


func get_health_change(char_health: float, char_max_health: float) -> float:
	return (
			health
			+ char_health * (health_percent * 0.01)
			+ char_max_health * (max_health_percent * 0.01)
	)


func get_magic_change(char_magic: float, char_max_magic: float) -> float:
	return (
			magic
			+ char_magic * (magic_percent * 0.01)
			+ char_max_magic * (max_magic_percent * 0.01)
	)


func _to_string() -> String:
	return "BattlePayload:\n" + get_effect_description() + "\n"
