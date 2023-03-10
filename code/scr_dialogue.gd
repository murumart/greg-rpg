extends Resource
class_name Dialogue

@export var name := &""
@export var lines : Array[DialogueLine]
@export var alias : String = ""


func size() -> int:
	return lines.size()


func get_line(index: int) -> DialogueLine:
	if not index < size():
		push_error("dialogue %s: index out of bounds" % name)
		return DialogueLine.new()
	if index < 0:
		push_error("dialogue %s: index out of bounds" % name)
		return DialogueLine.new()
	return lines[index]
