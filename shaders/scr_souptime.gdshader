shader_type canvas_item;
uniform sampler2D Gradient : hint_default_white;


// TransformUV

vec2 transformUVFunc(vec2 _uv_transform, vec2 _scale_uv_, vec2 _pivot_scale_uv_, vec2 _offset_uv_, float _rotate_uv, vec2 _pivot_rotate_uv_){
	_uv_transform -= _offset_uv_; // offset
	_uv_transform = (_uv_transform - _pivot_scale_uv_) * _scale_uv_ + _pivot_scale_uv_; // zoom
	vec2 _rot_uv_angl = vec2(cos(_rotate_uv), sin(_rotate_uv));
	mat2 _rot_matrix = mat2(vec2(_rot_uv_angl.x, - _rot_uv_angl.y), vec2(_rot_uv_angl.y, _rot_uv_angl.x));
	_uv_transform = (_uv_transform - _pivot_rotate_uv_) * _rot_matrix + _pivot_rotate_uv_; // rotate
	return _uv_transform;
}

// TilingAndOffsetUVAnimated

vec2 tilingNoffsetAnimatedFunc(vec2 _uv_tN0A, float _t1me_tN0A, vec2 _offset_tN0A){
	return vec2(mod((_uv_tN0A.x + _offset_tN0A.x * _t1me_tN0A), 1.0), mod((_uv_tN0A.y + _offset_tN0A.y * _t1me_tN0A), 1.0));
}

// TileUV

vec2 t1leMapUV(vec2 _uv_t1le_t1mp, float _w1dth_t1mp, float _he1ght_t1mp, float _t1le_nmbr_t1mp){
	_t1le_nmbr_t1mp = min(max(floor(_t1le_nmbr_t1mp), 0.0), _w1dth_t1mp * _he1ght_t1mp - 1.0);
	vec2 tcrcp = vec2(1.0) / vec2(_w1dth_t1mp, _he1ght_t1mp);
	float ty =floor(_t1le_nmbr_t1mp * tcrcp.x);
	float tx = _t1le_nmbr_t1mp - _w1dth_t1mp * ty;
	return (_uv_t1le_t1mp + vec2(tx, ty)) * tcrcp;
}

// TwirlUV

vec3 twirlUVFunc(vec2 _uv_twirlUVFunc, vec2 _pivot_twirlUVFunc, float _amount_twirlUVFunc){
	_uv_twirlUVFunc -= _pivot_twirlUVFunc;
	float _angle_twirlUVFunc = atan(_uv_twirlUVFunc.y, _uv_twirlUVFunc.x);
	float _radiusTemp_twirlUVFunc = length(_uv_twirlUVFunc);
	_angle_twirlUVFunc += _radiusTemp_twirlUVFunc * _amount_twirlUVFunc;
	return vec3(_radiusTemp_twirlUVFunc * vec2(cos(_angle_twirlUVFunc), sin(_angle_twirlUVFunc)) + 0.5, 0.0);
}

// ZoomBlur

vec4 zoomBlurFunc(sampler2D _tex_z00m_blur, vec2 _uv_z00m_blur, int _amount_z00m_blur, vec2 _center_zoom, float _lgt_z00m_blur, float _lod_z00m_blur){
	vec4 _col_z00m_blur;
	if (_lod_z00m_blur < 0.0){
		_col_z00m_blur = texture(_tex_z00m_blur, _uv_z00m_blur);
		for (int i = 1; i <= _amount_z00m_blur; i++){
			float _temp_d_z00m_blur = _lgt_z00m_blur * float(i);
			vec2 px = _uv_z00m_blur * (1.0 - _temp_d_z00m_blur) + _center_zoom * _temp_d_z00m_blur;
			_col_z00m_blur += texture(_tex_z00m_blur, px);
		}
	}else{
		_col_z00m_blur = textureLod(_tex_z00m_blur, _uv_z00m_blur, _lod_z00m_blur);
		for (int i = 1; i <= _amount_z00m_blur; i++){
			float _temp_d_z00m_blur = _lgt_z00m_blur * float(i);
			vec2 px = _uv_z00m_blur * (1.0 - _temp_d_z00m_blur) + _center_zoom * _temp_d_z00m_blur;
			_col_z00m_blur += textureLod(_tex_z00m_blur, px, _lod_z00m_blur);
		}
	}
	_col_z00m_blur = _col_z00m_blur / float(_amount_z00m_blur + 1);
	return _col_z00m_blur;
}

// GradientMapping

vec4 gradientMappingFunc(vec3 _c0l_base_gm, float _grad_offset, sampler2D _palette_gm, bool _use_c0l_cycle){
	float avg_c0l = 0.2126 * _c0l_base_gm.r + 0.7152 * _c0l_base_gm.g + 0.0722 * _c0l_base_gm.b;
	if (_use_c0l_cycle){
		return texture(_palette_gm, mod(vec2(avg_c0l + _grad_offset, 0), vec2(1.0)));
	} else{
		return texture(_palette_gm, vec2(avg_c0l + _grad_offset, 0));
	}
}


void vertex() {
// Output:0

}

void fragment() {
// Color:32
	vec3 n_out32p0 = vec3(0.510542, 0.510542, 0.510542);
	float n_out32p1 = 1.000000;

// Input:2
	vec3 n_out2p0 = vec3(SCREEN_UV, 0.0);

// SinTIME:28
	float n_in28p0 = 0.20000;
	float n_in28p1 = 4.00000;
	float n_out28p0;
	{
		n_out28p0 = n_in28p1 * sin(n_in28p0 * TIME);
	}

// ScalarOp:42
	float n_in42p1 = 7.00000;
	float n_out42p0 = n_out28p0 + n_in42p1;

// VectorCompose:27
	float n_in27p0 = 4.00000;
	float n_in27p2 = 0.00000;
	vec3 n_out27p0 = vec3(n_in27p0, n_out42p0, n_in27p2);

// ScaledTIME:5
	float n_in5p0 = 0.10000;
	float n_out5p0;
	{
		n_out5p0 = n_in5p0 * TIME;
	}

// TransformUV:4
	vec3 n_in4p1 = vec3(0.00000, 0.00000, 0.00000);
	vec3 n_in4p3 = vec3(0.50000, 0.50000, 0.00000);
	vec3 n_in4p5 = vec3(1.00000, 1.00000, 0.00000);
	vec3 n_out4p0;
	{
		n_out4p0.xy = transformUVFunc(n_out2p0.xy, n_out27p0.xy, n_in4p3.xy, n_in4p1.xy, n_out5p0, n_in4p5.xy);
	}

// ScaledTIME:8
	float n_in8p0 = 0.10000;
	float n_out8p0;
	{
		n_out8p0 = n_in8p0 * TIME;
	}

// TilingAndOffsetUVAnimated:7
	vec3 n_in7p1 = vec3(0.00000, 1.00000, 0.00000);
	vec3 n_out7p0;
	{
		n_out7p0.xy = n_out7p0.xy + tilingNoffsetAnimatedFunc(n_out4p0.xy, n_out8p0, n_in7p1.xy);
	}

// TileUV:14
	float n_in14p1 = 3.00000;
	float n_in14p2 = 3.00000;
	float n_in14p3 = 0.00000;
	vec3 n_out14p0;
	{
		n_out14p0.xy = t1leMapUV(n_out7p0.xy, n_in14p1, n_in14p2, n_in14p3);
	}

// Color:11
	vec3 n_out11p0 = vec3(1.000000, 1.000000, 1.000000);
	float n_out11p1 = 1.000000;

// ColorOp:16
	vec3 n_out16p0 = abs(n_out14p0 - vec3(n_out11p1));

// ColorOp:18
	vec3 n_out18p0 = vec3(1.0) - (vec3(1.0) - n_out32p0) / (n_out16p0);

// Input:35
	vec3 n_out35p0 = vec3(SCREEN_UV, 0.0);

// VectorMix:34
	vec3 n_in34p2 = vec3(0.00000, 0.50000, 0.50000);
	vec3 n_out34p0 = mix(n_out14p0, n_out35p0, n_in34p2);

// SinTIME:23
	float n_in23p0 = 0.10000;
	float n_in23p1 = 80.00000;
	float n_out23p0;
	{
		n_out23p0 = n_in23p1 * sin(n_in23p0 * TIME);
	}

// ScalarOp:26
	float n_in26p1 = 80.00000;
	float n_out26p0 = n_out23p0 + n_in26p1;

// ScalarOp:25
	float n_in25p1 = 111.00000;
	float n_out25p0 = n_out26p0 + n_in25p1;

// TwirlUV:19
	vec3 n_in19p2 = vec3(0.60000, 0.70000, 0.00000);
	vec3 n_out19p0;
	{
		n_out19p0 = twirlUVFunc(n_out34p0.xy, n_in19p2.xy, n_out25p0);
	}

// ZoomBlur:38
	float n_in38p2 = -3.00000;
	vec3 n_in38p3 = vec3(0.50000, 0.50000, 0.00000);
	float n_in38p4 = 10.00000;
	float n_in38p5 = -2.00000;
	vec3 n_out38p0;
	float n_out38p1;
	{
		vec4 n_out38p0n_out38p1 = zoomBlurFunc(TEXTURE, n_out19p0.xy, int(n_in38p4), n_in38p3.xy, n_in38p5, n_in38p2);
		n_out38p0 = n_out38p0n_out38p1.rgb;
		n_out38p1 = n_out38p0n_out38p1.a;
	}

// SinTIME:40
	float n_in40p0 = 0.10000;
	float n_in40p1 = 0.50000;
	float n_out40p0;
	{
		n_out40p0 = n_in40p1 * sin(n_in40p0 * TIME);
	}

// ScalarOp:41
	float n_in41p1 = 0.50000;
	float n_out41p0 = n_out40p0 + n_in41p1;

// VectorScalarMix:39
	vec3 n_out39p0 = mix(n_out19p0, n_out38p0, n_out41p0);

// ColorOp:20
	vec3 n_out20p0 = (n_out18p0) / (vec3(1.0) - n_out39p0);

// ColorOp:22
	vec3 n_out22p0 = vec3(1.0) - (vec3(1.0) - n_out20p0) * (vec3(1.0) - n_out20p0);

// ScaledTIME:43
	float n_in43p0 = 1.00000;
	float n_out43p0;
	{
		n_out43p0 = n_in43p0 * TIME;
	}

// GradientMapping:36
	float n_in36p1 = 1.00000;
	float n_in36p2 = 0.00000;
	vec3 n_out36p0;
	float n_out36p1;
	{
		vec4 n_out36p0n_out36p1 = gradientMappingFunc(n_out22p0, n_in36p2, Gradient, n_out43p0 > 0.0 ? true : false);
		n_out36p0 = n_out36p0n_out36p1.rgb;
		n_out36p1 = n_out36p0n_out36p1.a * n_in36p1;
	}

// Output:0
	COLOR.rgb = n_out36p0;

}

void light() {
// Output:0

}