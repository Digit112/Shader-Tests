shader_type spatial;

void fragment() {
	ALBEDO = vec3(mod(UV.x, 1), mod(UV.y, 1), 0.0);
}