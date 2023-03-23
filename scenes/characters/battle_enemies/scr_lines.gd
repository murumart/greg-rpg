@tool
extends CanvasGroup


func _process(delta: float) -> void:
	if not is_inside_tree(): return
	var lines := $Torso/Lines.get_children()
	var connections := $Torso/Head/Connections.get_children()
	
	for i in lines.size():
		var line := lines[i] as Line2D
		line.points[0] = line.to_local(connections[i].global_position)
