@tool
class_name VisualShaderNodePolarToCartesian extends VisualShaderNodeCustom


func _init() -> void:
	set_input_port_default_value(0, 0.0)


func _get_category() -> String:
	return "Vector"


func _get_input_port_count() -> int: return 1
func _get_output_port_count() -> int: return 1


func _get_subcategory() -> String:
	return "Functions"


func _get_output_port_name(_port: int) -> String:
	return "cartesian"


func _get_input_port_name(_port: int) -> String:
	return "polar"


func _get_input_port_type(_port: int) -> PortType:
	return PortType.PORT_TYPE_VECTOR_2D


func _get_output_port_type(_port: int) -> PortType:
	return PortType.PORT_TYPE_VECTOR_2D


func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, _type: VisualShader.Type) -> String:
	var iv = input_vars[1]
	return "%s = vec2(%s.y * cos(%s.x), %s.y * sin(%s.x));" % [output_vars[0], iv, iv, iv, iv]
