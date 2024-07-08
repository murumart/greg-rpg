@tool
class_name CanvasModulateGroup extends CanvasModulate

var colors: Array[ColorContainer]:
	get:
		var arr: Array[ColorContainer] = []
		arr.append_array(get_children())
		return arr


func _ready() -> void:
	colors.map(func(a): a.color_changed.connect(self._color_updated.unbind(1)))
	_color_updated()


func _color_updated() -> void:
	color = Color.WHITE
	for c in colors:
		match c.blend_mode:
			ColorContainer.BlendModes.MULTIPLY:
				color *= c.color
			ColorContainer.BlendModes.LERP:
				color = color.lerp(c.color, 0.5)
			ColorContainer.BlendModes.BLEND:
				color = color.blend(c.color)
