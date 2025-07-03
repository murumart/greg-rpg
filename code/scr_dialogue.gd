class_name Dialogue extends Resource

# this stores dialogue lines

@export var name := &""
@export var lines: Array[DialogueLine]
@export var alias: String = ""


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


func add_line(line: DialogueLine, ix: int = -1) -> DialogueLine:
	if ix == -1:
		lines.push_back(line)
	else:
		var err := lines.insert(ix, line)
		assert(err == OK)
	return line


func _to_string() -> String:
	var string := "DIALOGUE %s, %s lines:" % [name, lines.size()]
	var i := 0
	for line in lines:
		string += "\n\t" + "l:" + str(i) + " " + str(line)
		i += 1
	return string + "\n"
