# https://github.com/arkology/ShaderV/blob/master/addons/shaderV/uv/distortionUV.gd
@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeUVdistortion

func _init() -> void:
	set_input_port_default_value(1, 0)
	set_input_port_default_value(2, 0)
	set_input_port_default_value(3, 0)
	set_input_port_default_value(4, 0)

func _get_name() -> String:
	return "DistortionUV"

func _get_category() -> String:
	return "UV"

#func _get_subcategory():
#	return ""

func _get_description() -> String:
	return "Wave-like UV distortion"

func _get_return_icon_type() -> int:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_input_port_count() -> int:
	return 5

func _get_input_port_name(port: int):
	match port:
		0:
			return "uv"
		1:
			return "waveX"
		2:
			return "waveY"
		3:
			return "distortX"
		4:
			return "distortY"

func _get_input_port_type(port: int):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR
		2:
			return VisualShaderNode.PORT_TYPE_SCALAR
		3:
			return VisualShaderNode.PORT_TYPE_SCALAR
		4:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(port: int) -> String:
	return "uv"

func _get_output_port_type(port: int) -> int:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_global_code(mode: int) -> String:
	var code : String = """
vec2 _distortionUV(vec2 _distortion_uv, vec2 _distortion_vect, vec2 _distortion_wave_vect) {
	_distortion_uv.x += sin(_distortion_uv.y * _distortion_wave_vect.x) * _distortion_vect.x;
	_distortion_uv.y += sin(_distortion_uv.x * _distortion_wave_vect.y) * _distortion_vect.y;
	return _distortion_uv;
}
"""
	return code

func _get_code(input_vars: Array, output_vars: Array, mode: int, type: int) -> String:
	var uv = "UV"
	
	if input_vars[0]:
		uv = input_vars[0]
	
	return "%s.xy = _distortionUV(%s.xy, vec2(%s, %s), vec2(%s, %s));" % [
			output_vars[0], uv, input_vars[3], input_vars[4], input_vars[1], input_vars[2]]
