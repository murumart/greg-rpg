@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeUVrotate

func _init() -> void:
	set_input_port_default_value(1, 0.0)
	set_input_port_default_value(2, Vector3(0.5, 0.5, 0))

func _get_name() -> String:
	return "RotateUV"

func _get_category() -> String:
	return "UV"

#func _get_subcategory():
#	return ""

func _get_description() -> String:
	return "Rotate UV by angle in radians relative to pivot vector"

func _get_return_icon_type() -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_input_port_count() -> int:
	return 3

func _get_input_port_name(port: int):
	match port:
		0:
			return "uv"
		1:
			return "angle"
		2:
			return "pivot"

func _get_input_port_type(port: int):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR
		2:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port: int) -> String:
	return "uv"

func _get_output_port_type(_port: int) -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_global_code(_mode: Shader.Mode) -> String:
	return """
vec2 r0tateUVFunc(vec2 _uv_r0tate, vec2 _pivot_r0tate, float _r0tation_r0tate){
	//_r0tation_r0tate = radians(_r0tationDeg_r0tate);
	vec2 _r0tAngle = vec2(cos(_r0tation_r0tate), sin(_r0tation_r0tate));
	_uv_r0tate.xy -= _pivot_r0tate;
	_uv_r0tate.xy = vec2((_uv_r0tate.x*_r0tAngle.x-_uv_r0tate.y*_r0tAngle.y),(_uv_r0tate.x*_r0tAngle.y+_uv_r0tate.y*_r0tAngle.x));
	_uv_r0tate.xy += _pivot_r0tate;
	return _uv_r0tate;
}
"""

func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, _type: VisualShader.Type) -> String:
	var uv = "UV"

	if input_vars[0]:
		uv = input_vars[0]

	return output_vars[0] + " = r0tateUVFunc(%s, %s.xy, %s);" % [uv, input_vars[2], input_vars[1]]
