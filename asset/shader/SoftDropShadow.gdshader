shader_type canvas_item;
render_mode skip_vertex_transform;

uniform bool shadow_only = false;
uniform vec4 shadow_color : source_color;
uniform float blur_std = 0.4;

varying vec4 modulate;

void vertex() {
	vec2 texture_size = vec2(1.0, 1.0) / TEXTURE_PIXEL_SIZE;
	
	float padding = ceil(blur_std * 3.0);
	VERTEX = VERTEX - texture_size * 0.5;
	VERTEX = VERTEX * (vec2(1.0, 1.0) + padding * 2.0 * TEXTURE_PIXEL_SIZE);
	VERTEX = VERTEX + texture_size * 0.5;
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	
	vec2 factor = (vec2(1, 1) + 2.0 * padding * TEXTURE_PIXEL_SIZE);
	UV = factor * UV + vec2(0.5, 0.5) - 0.5 * factor;
	
	modulate = COLOR;
}

vec4 padded_sample(sampler2D tex, vec2 uv) {
	vec2 t = abs(uv - vec2(0.5, 0.5));
	float b = (t.x >= 0.5 || t.y >= 0.5) ? 0.0 : 1.0;
	return b * texture(tex, uv);
}

float erf(float x) {
	return 2.0 / sqrt(PI) * sign(x) * sqrt(1.0 - exp(-x*x)) * (sqrt(PI) / 2.0 + 31.0 * exp(-x*x) / 200.0 - 341.0 * exp(-2.0 * x * x) / 8000.0);
}

float gaussian(float x) {
	return 1.0 / sqrt(8.0) / blur_std + erf(x / sqrt(2.0) / blur_std) / sqrt(PI);
}

void fragment() {
	float weight = 0.0;
	vec2 coord = UV / TEXTURE_PIXEL_SIZE;
	coord -= floor(coord);
	float blur_radius = ceil(blur_std * 3.0);
	
	for (float x = -float(blur_radius); x <= float(blur_radius); ++x) {
		for (float y = -float(blur_radius); y <= float(blur_radius); ++y) {
			weight += (gaussian(-coord.x + x + 1.0) - gaussian(-coord.x + x))
			    * (gaussian(-coord.y + y + 1.0) - gaussian(-coord.y + y))
				* padded_sample(TEXTURE, UV + vec2(x, y) * TEXTURE_PIXEL_SIZE).a;
		}
	}
	
	vec4 c = padded_sample(TEXTURE, UV);
	float e = shadow_only ? 0.0 : 1.0;
	COLOR = c.a * e * c + (1.0 - c.a * e) * vec4(1.0, 1.0, 1.0, weight) * shadow_color;
	COLOR *= modulate;
}
