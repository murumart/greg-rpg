@tool
class_name VisualShaderNodeSuperformula extends VisualShaderNodeCustom


func _init() -> void:
	set_input_port_default_value(0, 0.0)
	set_input_port_default_value(1, 0.0)
	set_input_port_default_value(2, 0.0)
	set_input_port_default_value(3, 0.0)
	set_input_port_default_value(4, 0.0)
	set_input_port_default_value(5, 0.0)
	set_input_port_default_value(6, 0.0)


func _get_input_port_count() -> int:
	return 7


func _get_output_port_count() -> int:
	return 1


func _get_name() -> String:
	return "Superformula"


func _get_category() -> String:
	return "Scalar"


func _get_subcategory() -> String:
	return "Functions"


func _get_input_port_name(port: int) -> String:
	match port:
		0: return "phi"
		1: return "a"
		2: return "b"
		3: return "m"
		4: return "n1"
		5: return "n2"
		6: return "n3"
	return "???"


func _get_global_code(_mode: Shader.Mode) -> String:
	return """
		float _superformula(float phi, float a, float b, float m, float n1, float n2, float n3) {
			float leftside = pow(abs(cos((m * phi) / 4.0) / a), n2);
			float rightside = pow(abs(sin((m * phi) / 4.0) / b), n3);
			return pow(leftside + rightside, -1.0 / n1);
		}
	"""


func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, _type: VisualShader.Type) -> String:
	return "%s = _superformula(%s, %s, %s, %s, %s, %s, %s);" % [
		output_vars[0],
		input_vars[0],
		input_vars[1],
		input_vars[2],
		input_vars[3],
		input_vars[4],
		input_vars[5],
		input_vars[6],
	]
