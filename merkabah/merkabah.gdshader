shader_type spatial;
render_mode unshaded;

uniform sampler2D tex;

uniform float test;

void fragment() {
	ALBEDO = texture(
		tex,
		(SCREEN_UV - vec2(0.5, 0.5)) * 2.0 + vec2(0.5, 0.5)
	).xyz * 1.0;
	ALPHA = 1.0;
}

//void light() {}