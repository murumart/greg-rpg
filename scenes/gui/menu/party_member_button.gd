extends Button

@onready var member_info: PartyMemberInfoPanel = $MemberInfo
@onready var level_label: Label = $LevelLabel


func display(k: Character) -> void:
	member_info.display(k)
	level_label.text = "lvl " + str(k.level)
