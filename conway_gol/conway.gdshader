shader_type spatial;

const uint grid_width = uint(40);
const uint grid_height = uint(40);
const uint grid_size = uint(1600); // Must be set to grid_width*grid_height.

uniform uint grid[grid_size];

void fragment() {
	uint x = uint(UV.x * float(grid_width));
	uint y = uint(UV.y * float(grid_height));
	
	uint i = y*grid_width + x;
	float col = float(grid[i]);
	
	ALBEDO = vec3(col, col, col);
}
