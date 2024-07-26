extends Resource
class_name Spirit

# resource for storing spirit data

enum Uses {NONE = -1, HEALING, HURTING, BUFFING, DEBUFFING}
enum Reach {LOCAL, ALL, TEAM}
const USES_POSITIVE := [Uses.HEALING, Uses.BUFFING]
const USES_NEGATIVE := [Uses.HURTING, Uses.DEBUFFING]

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
@export var payload_reception_wait := 0.0
@export var wait := 0.0
@export var wait_before := 0.0
@export var payload: BattlePayload


func get_effect_description() -> String:
	var text := payload.get_effect_description() as String

	match reach:
		Reach.LOCAL:
			pass
		Reach.ALL:
			text += "@ all\n"
		Reach.TEAM:
			text += "@ one team\n"
	return text
