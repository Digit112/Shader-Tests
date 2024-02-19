shader_type spatial;

// The texture to sample. With no rotation set,
// this will only sample pixels belonging to an equilateral triangle in the center.
// Only the pixels within the ellipse cicumscribed by the image may be sampled, with any rotation.
// To avoid stretching, the image should be square and applied to a surface wth 0 Gaussian curvature.
uniform sampler2D base;

// The number of times the texture will be tiled both vertically and horizontally.
// If this is divisible by three, the whole texture will tile horizontally.
// If this is divisible by 6, the whole texture will tile horizontally and vertically.
uniform float num_tiles;

// Applies a rotation of theta radians to the sampled region.
uniform float theta;

void fragment() {
	vec2 nUV = vec2((UV.x - UV.y / 2.0) * num_tiles, UV.y * num_tiles);
	
	ivec2 nUVi = ivec2(floor(nUV));
	nUV = vec2(fract(nUV.x), fract(nUV.y));
	
	if (nUV.x + nUV.y > 1.0) {
		nUV = vec2(mod(-nUV.y, 1), mod(-nUV.x, 1));
	}
	
	for (int i = 0; i < nUVi.x % 3; i++) {
		nUV = vec2(1.0 - nUV.x - nUV.y, nUV.x);
	}
	
	for (int i = 0; i < nUVi.y % 3; i++) {
		nUV = vec2(nUV.y, 1.0 - nUV.x - nUV.y);
	}
	
	vec2 old_UV = vec2(nUV.x + nUV.y / 2.0, nUV.y);
	old_UV.y *= sqrt(3) / 2.0; // Make the sampled region an equilateral triangle.
	old_UV.y += (1.0 - sqrt(3) / 2.0); // Center the sampled region on the image.
	
	// Shrink the sampled region so as not to clip the image with any rotation.
	// Also rotates the sampled region.
	old_UV -= vec2(0.5, 0.5);
	old_UV *= sqrt(4.0 / 7.0);
	
	float ct = cos(theta);
	float st = sin(theta);
	old_UV = vec2(old_UV.x*ct - old_UV.y*st, old_UV.x*st + old_UV.y*ct);
	old_UV += vec2(0.5, 0.5);
	
	
	ALBEDO = texture(base, old_UV).rgb;
}
