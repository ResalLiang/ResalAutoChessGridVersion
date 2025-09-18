shader_type canvas_item;
render_mode skip_vertex_transform;

// 描边设置
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool enable_outline = true;

// 闪烁效果设置
uniform bool enable_blink = false;
uniform vec4 blink_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float blink_time_scale : hint_range(0.0, 10.0, 0.1) = 2.0;

// 阴影/光晕设置
uniform bool enable_shadow = true;
uniform bool shadow_only = false;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float blur_std : hint_range(0.1, 5.0, 0.1) = 1.0;

varying vec4 modulate;

// 用于边界外采样的函数
vec4 padded_sample(sampler2D tex, vec2 uv) {
	vec2 t = abs(uv - vec2(0.5, 0.5));
	float b = (t.x >= 0.5 || t.y >= 0.5) ? 0.0 : 1.0;
	return b * texture(tex, uv);
}

// 误差函数近似
float erf(float x) {
	return 2.0 / sqrt(PI) * sign(x) * sqrt(1.0 - exp(-x*x)) * (sqrt(PI) / 2.0 + 31.0 * exp(-x*x) / 200.0 - 341.0 * exp(-2.0 * x * x) / 8000.0);
}

// 高斯函数
float gaussian(float x) {
	return 1.0 / sqrt(8.0) / blur_std + erf(x / sqrt(2.0) / blur_std) / sqrt(PI);
}

//// 高斯函数 - 修正实现
//float gaussian(float x) {
	//float pi = 3.14159265359;
	//return exp(-0.5 * x * x / (blur_std * blur_std)) / (blur_std * sqrt(2.0 * pi));
//}

void vertex() {
	vec2 texture_size = vec2(1.0, 1.0) / TEXTURE_PIXEL_SIZE;
	
	// 计算需要的padding：描边1像素 + 阴影模糊半径
	float outline_padding = enable_outline ? 1.0 : 0.0;
	float shadow_padding = enable_shadow ? ceil(blur_std * 3.0) : 0.0;
	float total_padding = outline_padding + shadow_padding;
	
	// 扩展顶点以容纳描边和阴影
	VERTEX = VERTEX - texture_size * 0.5;
	VERTEX = VERTEX * (vec2(1.0, 1.0) + total_padding * 2.0 * TEXTURE_PIXEL_SIZE);
	VERTEX = VERTEX + texture_size * 0.5;
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	
	// 调整UV坐标
	vec2 factor = (vec2(1, 1) + 2.0 * total_padding * TEXTURE_PIXEL_SIZE);
	UV = factor * UV + vec2(0.5, 0.5) - 0.5 * factor;
	
	modulate = COLOR;
}

//void vertex() {
	//vec2 texture_size = vec2(1.0, 1.0) / TEXTURE_PIXEL_SIZE;
//
	//// 计算需要的padding
	//float outline_padding = enable_outline ? 1.0 : 0.0;
	//float shadow_padding = enable_shadow ? ceil(blur_std * 3.0) : 0.0;
	//float total_padding = outline_padding + shadow_padding;
//
	//// 修正：先计算局部坐标的扩展
	//vec2 expanded_vertex = VERTEX;
	//expanded_vertex = expanded_vertex - texture_size * 0.5;
	//expanded_vertex = expanded_vertex * (vec2(1.0, 1.0) + total_padding * 2.0 * TEXTURE_PIXEL_SIZE);
	//expanded_vertex = expanded_vertex + texture_size * 0.5;
//
	//// 然后应用变换矩阵
	//VERTEX = (MODEL_MATRIX * vec4(expanded_vertex, 0.0, 1.0)).xy;
//
	//// 调整UV坐标
	//vec2 factor = (vec2(1.0, 1.0) + 2.0 * total_padding * TEXTURE_PIXEL_SIZE);
	//UV = factor * UV + vec2(0.5, 0.5) - 0.5 * factor;
//
	//modulate = COLOR;
//}

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	vec4 original_color = padded_sample(TEXTURE, UV);
	
	// === 1. 像素完美描边检测 ===
	bool has_outline = false;
	if (enable_outline && original_color.a == 0.0) {
		// 检查8个相邻像素
		bool within = false;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(1.0, 1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(1.0, -1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(-1.0, 1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(-1.0, -1.0)).a > 0.0;
		within = within || padded_sample(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a > 0.0;
		
		has_outline = within;
	}
	
	// === 2. 计算阴影/光晕 ===
	float shadow_weight = 0.0;
	if (enable_shadow) {
		vec2 coord = UV / TEXTURE_PIXEL_SIZE;
		coord -= floor(coord);
		float blur_radius = ceil(blur_std * 3.0);
		
		for (float x = -float(blur_radius); x <= float(blur_radius); ++x) {
			for (float y = -float(blur_radius); y <= float(blur_radius); ++y) {
				shadow_weight += (gaussian(-coord.x + x + 1.0) - gaussian(-coord.x + x))
					* (gaussian(-coord.y + y + 1.0) - gaussian(-coord.y + y))
					* padded_sample(TEXTURE, UV + vec2(x, y) * TEXTURE_PIXEL_SIZE).a;
			}
		}
	}

	//// === 2. 计算阴影/光晕 === 修正版本
	//float shadow_weight = 0.0;
	//if (enable_shadow) {
		//float blur_radius = ceil(blur_std * 3.0);
		//
		//for (float x = -blur_radius; x <= blur_radius; x += 1.0) {
			//for (float y = -blur_radius; y <= blur_radius; y += 1.0) {
				//vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
				//float distance = length(vec2(x, y));
				//float weight = gaussian(distance);
				//shadow_weight += weight * padded_sample(TEXTURE, UV + offset).a;
			//}
		//}
	//}
	
	// === 3. 组合最终颜色 ===
	vec4 final_color;
	
	if (original_color.a > 0.0) {
		// 原始像素：应用闪烁效果
		final_color = original_color;
		if (enable_blink && blink_time_scale > 0.0) {
			float blink_factor = 0.5 - 0.5 * cos(TIME * blink_time_scale);
			final_color = mix(final_color, final_color * blink_color, blink_factor);
		}
	} else if (has_outline) {
		// 描边像素：应用闪烁效果到描边
		final_color = outline_color;
		if (enable_blink && blink_time_scale > 0.0) {
			float blink_factor = 0.5 - 0.5 * cos(TIME * blink_time_scale);
			final_color = mix(final_color, final_color * blink_color, blink_factor);
		}
	} else if (enable_shadow && shadow_weight > 0.0) {
		// 阴影区域
		final_color = vec4(shadow_color.rgb, shadow_weight * shadow_color.a);
	} else {
		// 完全透明区域
		final_color = vec4(0.0, 0.0, 0.0, 0.0);
	}
	
	// 如果启用shadow_only模式，只显示阴影不显示原图
	if (shadow_only && enable_shadow) {
		if (original_color.a > 0.0 || has_outline) {
			final_color = vec4(0.0, 0.0, 0.0, 0.0);
		} else {
			final_color = vec4(shadow_color.rgb, shadow_weight * shadow_color.a);
		}
	}
	
	COLOR = final_color * modulate;
}

//extends Sprite2D
//
//func _ready():
    //创建shader材质
    //var shader_material = ShaderMaterial.new()
    //shader_material.shader = load("res://shaders/pixel_outline_shadow.gdshader")
    //material = shader_material
    //
    //设置参数
    //setup_outline()
    //setup_blink_effect()
    //setup_shadow()
//
//func setup_outline():
    //启用描边并设置颜色
    //material.set_shader_parameter("enable_outline", true)
    //material.set_shader_parameter("outline_color", Color.WHITE)
//
//func setup_blink_effect():
    //启用闪烁效果
    //material.set_shader_parameter("enable_blink", true)
    //material.set_shader_parameter("blink_color", Color.RED)
    //material.set_shader_parameter("blink_time_scale", 3.0)
//
//func setup_shadow():
    //启用阴影效果
    //material.set_shader_parameter("enable_shadow", true)
    //material.set_shader_parameter("shadow_color", Color(0, 0, 0, 0.6))
    //material.set_shader_parameter("blur_std", 2.0)
    //material.set_shader_parameter("shadow_only", false)
//
//动态切换效果的示例函数
//func toggle_blink():
    //var current = material.get_shader_parameter("enable_blink")
    //material.set_shader_parameter("enable_blink", !current)
//
//func set_outline_color(color: Color):
    //material.set_shader_parameter("outline_color", color)
