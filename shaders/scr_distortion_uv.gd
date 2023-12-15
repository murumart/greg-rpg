@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeUVdistortionAnimated

func _init() -> void:
	set_input_port_default_value(1, 0.0)
	set_input_port_default_value(2, 0.0)
	set_input_port_default_value(3, 0.0)
	set_input_port_default_value(4, 0.0)
	set_input_port_default_value(5, 1.0)
	set_input_port_default_value(6, 0.0)

func _get_name() -> String:
	return "DistortionUVAnimated"

func _get_category() -> String:
	return "UV"

func _get_subcategory() -> String:
	return "Animated"

func _get_description() -> String:
	return "Animated wave-like UV distortion"

func _get_return_icon_type() -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_input_port_count() -> int:
	return 7

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
		5:
			return "speed"
		6:
			return "time"

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
		5:
			return VisualShaderNode.PORT_TYPE_SCALAR
		6:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port: int) -> String:
	return "uv"

func _get_output_port_type(_port: int) -> VisualShaderNode.PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_global_code(_mode: Shader.Mode) -> String:
	var code: String = "vec2 _distortionUVAnimatedFunc(vec2 _uv_dist, float _distX_dist, float _distY_dist, float _waveX_dist, float _waveY_dist, float _spd_dist, float _time_dist){
	_uv_dist.x += sin(_uv_dist.y * _waveX_dist + _time_dist * _spd_dist) * _distX_dist;
	_uv_dist.y += sin(_uv_dist.x * _waveY_dist + _time_dist * _spd_dist) * _distY_dist;
	return _uv_dist;
}"
	return code

func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, _type: VisualShader.Type) -> String:
	var uv = "UV"
	
	if input_vars[0]:
		uv = input_vars[0]
	
	return "%s.xy = _distortionUVAnimatedFunc(%s.xy, %s, %s, %s, %s, %s, %s);" % [output_vars[0], uv, input_vars[3], input_vars[4], input_vars[1], input_vars[2], input_vars[5], input_vars[6]]
