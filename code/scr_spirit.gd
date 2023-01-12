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
@export var payload : BattlePayload
