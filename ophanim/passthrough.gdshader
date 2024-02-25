shader_type spatial;

uniform sampler2D tex;

void fragment() {
	ALBEDO = texture(tex, SCREEN_UV).xyz;
}

void light() {}