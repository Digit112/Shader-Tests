shader_type spatial;

// Renders a fractal by way of the holomorphic recurrence relation:
// Z[n] = Z[n-1]^2 + C
// where Z[0] is derived from the UV coordinates and C is constant.
// Values of Z[0] for which |Z[num_iters]| <= 2 sample the supplied texture and normal.
// Values of Z[0] for which |Z[i]| > 2 for any i < num_iters produce an albedo and appropriate normal value.
// The produced normals and albedos reflect a renormalized iteration count derived from the escape time of Z.

// In other words, it renders a Julia set fractal and produces a pretty picture.
// pixels that would otherwise be black sample the supplied texture instead.

uniform uint num_iters;

// Causes the palette (a rainbow) to repeat more frequently.
uniform float palette_mul;

uniform float saturation;
uniform float value;

// Controls the distance from the fragment (in UV space) from which another sample is taken.
// The additional samples are used to generate the surface normal.
// Should usually be set to a very small value like 0.001.
uniform float normal_sample_delta;

// Normal map Z-coordinate multiplier. Smaller values exaggerate the illusion of depth.
uniform float normal_z_mul;

// Texture to sample for unescaped points.
uniform sampler2D tex;

uniform vec2 C;

// Vector added to UV before apply transforms below
uniform vec2 UV_add;

// Vector multiplied (piecie-wise) by UV before applying transforms below.
uniform vec2 UV_mul;

// Transformation matrix from UV space to complex space.
uniform vec2 UV_to_Z_x;
uniform vec2 UV_to_Z_y;
uniform vec2 UV_to_Z_o;

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	int escaped_at[3] = {-1, -1, -1};
	float escaping_rad[3];
	
	vec2 my_UV = UV*UV_mul + UV_add;
	
	float theta = UV.y / 13.0 * 2.0 * 3.14159;
	float cth = cos(theta);
	float sth = sin(theta);
	
	for (int s = 0; s < 3; s++) {
		vec2 Z = vec2(
			UV_to_Z_x.x*mod(my_UV.x, 1) + UV_to_Z_y.x*mod(my_UV.y, 1) + UV_to_Z_o.x,
			UV_to_Z_x.y*mod(my_UV.x, 1) + UV_to_Z_y.y*mod(my_UV.y, 1) + UV_to_Z_o.y
		);
		
		vec2 my_C = vec2(
			C.x*cth - C.y*sth,
			2.0*C.x*C.y
		);
		
		if (s == 1) {
			Z.x += normal_sample_delta;
		}
		else if (s == 2) {
			Z.y += normal_sample_delta;
		}
		
		for (uint i = uint(0); i < num_iters; i++) {
			Z = vec2(
				Z.x * Z.x - Z.y * Z.y + my_C.x,
				2.0 * Z.x * Z.y + my_C.y
			);
			
			float sqr_abs = Z.x*Z.x + Z.y*Z.y;
			if (sqr_abs > 64.0) {
				escaped_at[s] = int(i);
				escaping_rad[s] = sqrt(sqr_abs);
				break;
			}
		}
		
		if (escaped_at[0] == -1) {
			ALBEDO = texture(tex, my_UV).xyz;
		}
		else {
			float renorm[3];
			float smth;
			
			renorm[0] = float(escaped_at[0]) + 1.0 - log(log(escaping_rad[0])) / log(2);
			smth = mod(renorm[0], palette_mul) / palette_mul;
			ALBEDO = hsv2rgb(vec3(smth, saturation, value));
			
			METALLIC = 0.4;
			ROUGHNESS = 0.4;
			
			// Check whether the normal exists.
			if (escaped_at[1] != -1 && escaped_at[2] != -1) {
				renorm[1] = float(escaped_at[1]) + 1.0 - log(log(escaping_rad[1])) / log(2);
				renorm[2] = float(escaped_at[2]) + 1.0 - log(log(escaping_rad[2])) / log(2);
				
				vec3 normal_vec = normalize(vec3(
					(renorm[1] - renorm[0]) / normal_sample_delta,
					(renorm[2] - renorm[0]) / normal_sample_delta,
					renorm[0] / normal_sample_delta * normal_z_mul
				));
				
				NORMAL_MAP = normal_vec;
				//ALBEDO = normal_vec; // Check normal
			}
		}
	}
}
