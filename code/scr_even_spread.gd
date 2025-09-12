@tool
extends Node2D

@export var radius := 120.0
@export var instant := true
@export_tool_button("arrange us") var arrange_us: Callable = arrange


func arrange() -> void:
	var amt := get_child_count()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	for i in amt:
		var child := get_child(i)
		var to: float = roundf(-radius/2.0 + radius/float(amt)*(i+1) - radius/float(amt)/2.0)
		tw.tween_property(child, "position:x", to, 0.5 if not instant else 0.0)
		#child.position.x = to
