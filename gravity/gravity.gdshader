shader_type spatial;

const uint num_particles_2 = uint(16);

uniform float positions[num_particles_2];

void fragment() {
	ALBEDO = vec3(1, 1, 1);
	for (uint i = uint(0); i < num_particles_2; i+=uint(2)) {
		float dx = UV.x - positions[i  ];
		float dy = UV.y - positions[i+uint(1)];
		
		float dis = sqrt(dx*dx + dy*dy);
		
		if (dis < 0.01) {
			ALBEDO = vec3(0, 0, 0);
			break;
		}
	}
}