shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0);
//Blinking modulates the base color.
//Set blink_time_scale to 0 if you don't want blinking.
uniform vec4 blink_color : source_color = vec4(1.0);
uniform float blink_time_scale : hint_range(0.0, 10.0, 0.1) = 0.0;

// 新增：单色化开关和颜色设置
uniform bool use_monochrome = false;
uniform vec4 monochrome_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // 默认橙色

// 计算亮度值
float get_luminance(vec3 color) {
	//return dot(color, vec3(0.299, 0.587, 0.114));
	return dot(color, vec3(0.33, 0.33, 0.33));
}

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	bool within = texture(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(1.0, 1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(1.0, -1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, -1.0)).a > 0.0;
	within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a > 0.0;
	bool outline = within && texture(TEXTURE, UV).a == 0.0;
	
	// 获取原始颜色
	vec4 original_color = COLOR;
	
	// 应用单色化效果
	if (use_monochrome && !outline) {
		// 计算原始颜色的亮度
		float luminance = get_luminance(original_color.rgb);
		// 根据亮度调整单色颜色的明暗
		vec3 mono_color = monochrome_color.rgb * luminance;
		// 保持原始alpha通道
		original_color = vec4(mono_color, original_color.a);
	}
	
	// 应用闪烁效果
	COLOR = mix(original_color, original_color * blink_color, 0.5 - 0.5 * cos(TIME * blink_time_scale));
	
	// 应用轮廓效果
	COLOR = float(!outline) * COLOR + float(outline) * outline_color;
}