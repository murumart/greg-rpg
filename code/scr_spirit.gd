extends Resource
class_name Spirit

# resource for storing spirit data

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
			text += criptions.get(eff.name, fname) + (" "+str(eff.strength)+" " if eff.strength != 1 else "") + " for %s\n" % eff.duration
	match reach:
		Reach.LOCAL: pass
		Reach.ALL:text += "@ all\n"
		Reach.TEAM: text += "@ one team"
	return text
