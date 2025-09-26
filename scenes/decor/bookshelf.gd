extends StaticBody2D

@export_multiline var lines: PackedStringArray
@onready var inspect_area: InspectArea = $InspectArea


func _ready() -> void:
	if lines.is_empty():
		return
	inspect_area.key = ""
	inspect_area.dialogue = Dialogue.new()
	for line in lines:
		inspect_area.dialogue.add_line(DialogueLine.mk(line))
