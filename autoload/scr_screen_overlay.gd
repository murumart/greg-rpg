extends CanvasLayer


func add_ui_child(node: Node, custom_z_index := 0, delete_on_scene_change := true):
	var node2d := Node2D.new()
	add_child(node2d)
	node2d.z_index = custom_z_index
	if delete_on_scene_change: node2d.add_to_group("free_on_scene_change")
	node2d.add_child(node)

