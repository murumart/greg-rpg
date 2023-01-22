extends Resource
class_name Item

enum Uses {NONE = -1, HEALING, HURTING, BUFFING, DEBUFFING, WEAPON, ARMOUR}

@export var name_in_file := &""

@export_group("Appearance")
@export var name := &""
@export_multiline var description := ""
@export var texture : Texture

@export_group("Behaviour")
@export var price := 0
@export var use := Uses.NONE
@export var payload : BattlePayload

