extends Resource
class_name Spirit

enum Uses {NONE = -1, HEALING, HURTING, BUFFING, DEBUFFING}
enum Reach {LOCAL, ALL, TEAM}

@export var name_in_file := &""

@export_group("Appearance")
@export var name := &""
@export_multiline var description := ""
@export var animation := &""
@export var use_animation := &""
@export var receive_animation := &""

@export_group("Behaviour")
@export var cost := 15
@export var use := Uses.NONE
@export var reach := Reach.LOCAL
@export var payload_reception_count := 1
@export var payload : BattlePayload


func get_effect_description() -> String:
	var text := ""
	text += "cost: %s\n" % cost
	if payload.health:
		text += "%s%s hp\n" % [Math.sign_symbol(payload.health), absf(payload.health)]
	if payload.health_percent:
		text += "%s%s " % [Math.sign_symbol(payload.health_percent), absf(payload.health_percent)]
		text += "% hp\n"
	if payload.max_health_percent:
		text += "%s%s " % [Math.sign_symbol(payload.max_health_percent), absf(payload.max_health_percent)]
		text += "% max hp\n"
	if payload.magic:
		text += "%s%s sp\n" % [Math.sign_symbol(payload.magic), absf(payload.magic)]
	if payload.magic_percent:
		text += "%s%s " % [Math.sign_symbol(payload.magic_percent), absf(payload.magic_percent)]
		text += "% sp\n"
	if payload.max_magic_percent:
		text += "%s%s " % [Math.sign_symbol(payload.max_magic_percent), absf(payload.max_magic_percent)]
		text += "% max sp\n"
	if payload.attack_increase:
		text += "%s%s atk" % [Math.sign_symbol(payload.attack_increase), absf(payload.attack_increase)]
		text += (" for %s turns\n" % payload.attack_increase_time)
	if payload.defense_increase:
		text += "%s%s def" % [Math.sign_symbol(payload.defense_increase), absf(payload.defense_increase)]
		text += (" for %s turns\n" % payload.defense_increase_time)
	if payload.speed_increase:
		text += "%s%s spd" % [Math.sign_symbol(payload.speed_increase), absf(payload.speed_increase)]
		text += (" for %s turns\n" % payload.speed_increase_time)
	return text
