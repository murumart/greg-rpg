extends Resource
class_name Item

# resource for storing item data

enum Uses {NONE = -1, HEALING, HURTING, BUFFING, DEBUFFING, WEAPON, ARMOUR}
const USES_EQUIPABLE := [Uses.WEAPON, Uses.ARMOUR]

@export var name_in_file := &""

@export_group("Appearance")
@export var name := &""
@export_multiline var description := ""
@export var texture : Texture
@export var attack_animation := ""
@export var play_sound : AudioStream

@export_group("Behaviour")
@export var price := 0
@export var use := Uses.NONE
@export var consume_on_use := true
@export var payload : BattlePayload: get = get_payload


func get_effect_description() -> String:
	var text := ""
	if not payload: return text
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
		text += "%s%s atk\n" % [Math.sign_symbol(payload.attack_increase), absf(payload.attack_increase)]
	if payload.defense_increase:
		text += "%s%s def\n" % [Math.sign_symbol(payload.defense_increase), absf(payload.defense_increase)]
	if payload.speed_increase:
		text += "%s%s spd\n" % [Math.sign_symbol(payload.speed_increase), absf(payload.speed_increase)]
	for eff in payload.effects:
		var fname := eff.name.replace("_", " ")
		var criptions := {
			"fire": "on fire"
		}
		var immuniscriptions := {}
		var curescriptions := {
			"fire": "fire extinguished"
		}
		if eff.duration < -1:
			text += immuniscriptions.get(eff.name, fname + " immunity") + " for %s\n" % absi(eff.duration)
		elif eff.duration == -1:
			text += curescriptions.get(eff.name, "cures " + fname + "\n")
		else:
			text += criptions.get(eff.name, fname) + (" "+Math.sign_symbol(eff.strength)+str(absf(eff.strength))+" " if eff.strength != 1 else "") + " for %s\n" % eff.duration
	if use == Uses.ARMOUR:
		text += "armour\n"
	if use == Uses.WEAPON:
		text += "weapon\n"
	return text


func get_payload() -> BattlePayload:
	#print(name, " payload accessed")
	return payload
