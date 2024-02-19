#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 4, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer Positions {
    float data[];
}
positions;

layout(set = 0, binding = 1, std430) restrict buffer Velocities {
    float data[];
}
velocities;

void main() {
	// Gravitational constant
	float Grav = 6E-90;
	
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
	uint offset = gl_GlobalInvocationID.x*2;
	
	// For all other partcles...
	for (uint i = 0; i < gl_WorkGroupSize.x * gl_NumWorkGroups.x; i++) {
		if (i != gl_GlobalInvocationID.x) { // Do not apply acceleration to self.
			uint alt_offset = i*2;
			
			// Get the vector from this particle to the neighboring particle
			float dx = positions.data[alt_offset  ] - positions.data[offset  ];
			float dy = positions.data[alt_offset+1] - positions.data[offset+1];
			
			if (dx != 0 || dy != 0) {
				// Caculate the force of gravity between these particles
				float sqr_dis = dx*dx + dy*dy;
				float dis = sqrt(sqr_dis);
				
				float force = max(Grav / sqr_dis, 0.5);
				
				// Apply acceleration due to gravity.
				velocities.data[offset  ] += dx / dis * force * 0.0167;
				velocities.data[offset+1] += dy / dis * force * 0.0167;
			}
		}
	}
	
	// Apply change in position due to velocity.
    positions.data[offset  ] += velocities.data[offset  ] * 0.0167;
    positions.data[offset+1] += velocities.data[offset+1] * 0.0167;
}