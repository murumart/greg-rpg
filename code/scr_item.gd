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
	var text := Math.get_effect_description(self)
	if use == Uses.ARMOUR:
		text += "armour\n"
	if use == Uses.WEAPON:
		text += "weapon\n"
	return text


func get_payload() -> BattlePayload:
	#print(name, " payload accessed")
	return payload
