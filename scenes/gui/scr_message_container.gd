class_name MessageContainer extends Control

var last_y := 0

@export var life_time := 1.2
@export var disappear_time := 1.0


func push_message(text: String, options := {}) -> void:
	var lab := Label.new()
	lab.text = text
	lab.size.x = size.x
	lab["theme_override_constants/outline_size"] = 2
	lab["theme_override_colors/font_outline_color"] = Color.BLACK
	add_child(lab)
	last_y = get_children().map(func(a: Control): return a.position.y).max() + 8
	lab.position.y = last_y
	lab.horizontal_alignment = options.get("alignment", HORIZONTAL_ALIGNMENT_LEFT)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(life_time)
	tw.tween_property(lab, "modulate:a", 0, disappear_time)
	tw.parallel().tween_property(lab, "position:y", last_y - 120, disappear_time)
	tw.tween_callback(func():
		lab.hide()
		lab.queue_free()
	)
