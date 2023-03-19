extends Resource
class_name Item

enum Uses {NONE = -1, HEALING, HURTING, BUFFING, DEBUFFING, WEAPON, ARMOUR}
const USES_EQUIPABLE := [Uses.WEAPON, Uses.ARMOUR]

@export var name_in_file := &""

@export_group("Appearance")
@export var name := &""
@export_multiline var description := ""
@export var texture : Texture
@export var attack_animation := ""

@export_group("Behaviour")
@export var price := 0
@export var use := Uses.NONE
@export var consume_on_use := true
@export var payload : BattlePayload: get = get_payload


func get_effect_description() -> String:
	var text := ""
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
		text += (" for %s turns\n" % payload.attack_increase_time) if not use == Uses.ARMOUR and not use == Uses.WEAPON else "\n"
	if payload.defense_increase:
		text += "%s%s def" % [Math.sign_symbol(payload.defense_increase), absf(payload.defense_increase)]
		text += (" for %s turns\n" % payload.defense_increase_time) if not use == Uses.ARMOUR and not use == Uses.WEAPON else "\n"
	if payload.speed_increase:
		text += "%s%s spd" % [Math.sign_symbol(payload.speed_increase), absf(payload.speed_increase)]
		text += (" for %s turns\n" % payload.speed_increase_time) if not use == Uses.ARMOUR and not use == Uses.WEAPON else "\n"
	if payload.confusion_time:
		text += "confusion for %s\n" % payload.confusion_time
	if payload.poison_time:
		text += "poison %s for %s\n" % [payload.poison_level, payload.poison_time] if payload.poison_time > 0 else "cures poison"
	if payload.coughing_time:
		text += "coughing %s for %s\n" % [payload.coughing_level, payload.coughing_time] if payload.coughing_time > 0 else "cures coughing"
	if use == Uses.ARMOUR:
		text += "armour\n"
	if use == Uses.WEAPON:
		text += "weapon\n"
	return text


func get_payload() -> BattlePayload:
	#print(name, " payload accessed")
	return payload
