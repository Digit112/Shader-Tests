#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 4, local_size_y = 4, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer InGrid {
    uint data[];
}
in_grid;

// A binding to the buffer we create in our script
layout(set = 0, binding = 1, std430) restrict buffer OutGrid {
    uint data[];
}
out_grid;


void main() {
	int width = 40;
	int height = 40;
	
	uint ind = gl_GlobalInvocationID.y*width + gl_GlobalInvocationID.x;
	
	uint num_neighbors = 0;
	for (int x = int(gl_GlobalInvocationID.x)-1; x <= int(gl_GlobalInvocationID.x)+1; x++) {
		for (int y = int(gl_GlobalInvocationID.y)-1; y <= int(gl_GlobalInvocationID.y)+1; y++) {
			uint n_ind = (y % height) * width + (x % width);
			
			if (n_ind != ind) {
				num_neighbors += in_grid.data[n_ind];
			}
		}
	}
	
	if (num_neighbors < 2 || num_neighbors > 3) {
		out_grid.data[ind] = 0;
	}
	else if (num_neighbors == 3) {
		out_grid.data[ind] = 1;
	}
	else {
		out_grid.data[ind] = in_grid.data[ind];
	}
	
	//in_grid.data[ind] = out_grid.data[ind];
}