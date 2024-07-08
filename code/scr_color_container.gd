@tool
class_name ColorContainer extends Node

enum BlendModes {MULTIPLY, LERP, BLEND}

signal color_changed(to: Color)

@export var color: Color = Color.WHITE:
	set(to):
		if not blend_mode == BlendModes.BLEND:
			to.a = 1.0
		color = to
		color_changed.emit(to)
@export var blend_mode := BlendModes.MULTIPLY:
	set(to):
		if not to == BlendModes.BLEND:
			color.a = 1.0
		blend_mode = to
		color_changed.emit(color)
