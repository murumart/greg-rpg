shader_type canvas_item;
uniform sampler2D Gradient : source_color;


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


void vertex() {
// Output:0

}

void fragment() {
// Color:32
	vec3 grey_colour = vec3(0.510542, 0.510542, 0.510542);

// Input:2
	vec3 screen_uv = vec3(SCREEN_UV, 0.0);

// SinTIME:28
	float sin_time_1 = 4.00000 * sin(0.20000 * TIME);

// VectorCompose:27
	vec3 four_seven_vector = vec3(4.00000, sin_time_1 + 7.00000, 0.00000);

// ScaledTIME:5
	float ten_perc_time = 0.10000 * TIME;

// TransformUV:4
	vec3 zerozero = vec3(0.00000, 0.00000, 0.00000);
	vec3 fivefive = vec3(0.50000, 0.50000, 0.00000);
	vec3 oneone = vec3(1.00000, 1.00000, 0.00000);
	vec3 transformed_uv;
	{
		transformed_uv.xy = transformUVFunc(screen_uv.xy, four_seven_vector.xy, fivefive.xy, zerozero.xy, ten_perc_time, oneone.xy);
	}

// TilingAndOffsetUVAnimated:7
	vec3 tilingoffset;
	{
		tilingoffset.xy = tilingNoffsetAnimatedFunc(transformed_uv.xy, ten_perc_time, vec2(0.0, 1.0));
	}

// TileUV:14
	vec3 tiled_uv;
	{
		tiled_uv.xy = t1leMapUV(tilingoffset.xy, 8.00000, 3.00000, 0.00000);
	}


// ColorOp:18
	vec3 operated_colour_18 = vec3(1.0) - (vec3(1.0) - grey_colour) / (abs(tiled_uv - vec3(1.000000)));

// VectorMix:34
	vec3 tile_screen_uv_mix = mix(tiled_uv, vec3(SCREEN_UV, 0.0), vec3(0.00000, 0.50000, 0.50000));

// SinTIME:23
	float eighty_time;
	{
		eighty_time = 80.00000 * sin(0.10000 * TIME);
	}

// TwirlUV:19
	vec3 twirled_uv;
	{
		twirled_uv = twirlUVFunc(tile_screen_uv_mix.xy, vec2(0.60000, 0.70000), eighty_time + 80.00000 + 111.00000);
	}

// ZoomBlur:38
	vec3 zoomblur;
	{
		vec4 zoomblurn_out38p1 = zoomBlurFunc(TEXTURE, twirled_uv.xy, int(10.00000), fivefive.xy, -2.00000, -3.00000);
		zoomblur = zoomblurn_out38p1.rgb;
	}

// SinTIME:40
	float halfsintime;
	{
		halfsintime = 0.50000 * sin(0.10000 * TIME);
	}

// VectorScalarMix:39
	vec3 twirl_zoom_mix = mix(twirled_uv, zoomblur, halfsintime + 0.50000);

// ColorOp:22
	vec3 colour_into_gradient = vec3(1.0) - (vec3(1.0) - (operated_colour_18) / (vec3(1.0) - twirl_zoom_mix)) * (vec3(1.0) - (operated_colour_18) / (vec3(1.0) - twirl_zoom_mix));


// GradientMapping:36
	vec3 final_output;
	{
		float inp = max(colour_into_gradient.r, 0.25);
		vec2 imp_pos = vec2(inp, 0);
		final_output = texture(Gradient, imp_pos).rbg;
	}

// Output:0
	COLOR.rgb = final_output.rgb;

}

void light() {
// Output:0

}