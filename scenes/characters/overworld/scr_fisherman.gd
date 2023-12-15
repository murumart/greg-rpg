@tool
extends Node2D

# fishermen npcs in the lake area

@export_enum("green", "blue", "yellow", "red", "bikeghost") var type: int = 0: set = _set_type
@export var line_length := 30: set = _set_line_lenght
@export var flip := false: set = _set_flip
@export var custom_lines: PackedStringArray = []
var cusdialpro := 0
@export var randomise_men := false: set = _randomise_men


func _set_line_lenght(to: int) -> void:
	line_length = to
	var line: Line2D = get_node_or_null("Pole/Line2D")
	if not is_instance_valid(line): return
	
	line.points[1].y = line_length


func _set_type(to: int) -> void:
	type = to
	
	var sprite: Sprite2D = get_node_or_null("Face")
	if not is_instance_valid(sprite): return
	# all fishermen looks are in this one file.
	# but if they weren't, i could still use this match statement
	match to:
		0:
			sprite.region_rect = Rect2i(0, 0, 16, 16)
		1:
			sprite.region_rect = Rect2i(16, 0, 16, 16)
		2:
			sprite.region_rect = Rect2i(0, 16, 16, 16)
		3:
			sprite.region_rect = Rect2i(16, 16, 16, 16)
		4:
			sprite.region_rect = Rect2i(48, 32, 16, 16)


func _set_flip(to: bool) -> void:
	flip = to
	
	var sprite: Sprite2D = get_node_or_null("Face")
	if is_instance_valid(sprite):
		sprite.flip_h = to
	var pole := get_node_or_null("Pole")
	if is_instance_valid(pole):
		pole.scale.x = remap(float(not flip), 0, 1, -1, 1)
		pole.position.x = remap(float(not flip), 0, 1, -2, 2)


func _on_interact() -> void:
	# the dialogue progress just loops around forever
	if not custom_lines.is_empty():
		SOL.dialogue(custom_lines[mini(cusdialpro, custom_lines.size() - 1)])
		cusdialpro += 1
		return
	var dialpr: int = DAT.get_data("fisher_progress", 0)
	dialpr = wrapi(dialpr + 1, 1, 6)
	DAT.set_data("fisher_progress", dialpr)
	SOL.dialogue("fisherman_%s" % dialpr)


func _randomise_men(_to: bool) -> void:
	if not is_inside_tree(): return
	var men := get_tree().get_nodes_in_group("fishermen")
	for man in men:
		man.type = randi() % 4

