extends Node3D

# Generates the geometry of the intersections of two counter-rotating tetrahedrons.
# Each vertically flipped.

# This is the core of the merkabah.
@export var mesh_inst : MeshInstance3D

# Difference between the rotation of the tetrahedra in radians.
var theta : float = 0

# Rate of counter-rotation in degrees per second.
# Whole mesh will be rotated in the opposite direction at half speed.
@export var counter_rotation_rate : float

# Time, in seconds, between mesh updates.
# Increase to reduce performance impact.
# Also affects rotation.
@export var update_delay : float

var timer : float

var my_mat : ShaderMaterial

# Returns the collision, if it exists, between the passed segment and the three
# faces of the passed tetrahedron which include the first point.
# Returns the position of the first intersection found as a Vector3,
# null if none was found.
# Could be resolved to only a single segment-tri intersection per call,
# As it is known which tri will be intersected. See "tetra_intersect_demo.blend"
func segment_intersects_tetra(from : Vector3, to : Vector3, tetra : Array[Vector3]) -> Variant:
	for v1_i in range(1, 3):
		for v2_i in range(v1_i+1, 4):
			var col = Geometry3D.segment_intersects_triangle(
				from, to, tetra[0], tetra[v1_i], tetra[v2_i]
			)
			
			#print(from, to, tetra[0], tetra[v1_i], tetra[v2_i])
			#print(col)
			if col != null:
				return col
	
	return null

func update_mesh():
	theta = fmod(theta, 2*PI/3)
	
	# Points of an equilateral tetrahedron.
	# A base lies in the xz plane.
	# The point not in the xy plane comes first.
	var tetra_v : Array[Vector3] = [
		Vector3(0,    sqrt(2.0/3),  0),
		Vector3(0,    0,           -sqrt(3)/3),
		Vector3(-0.5, 0,            sqrt(3)/6),
		Vector3(0.5,  0,            sqrt(3)/6)
	]
	
	# Points of the same tetrahedron, upside down with a single point in the xy plane.
	var tetra_v_inv : Array[Vector3] = [
		Vector3(0,    0,            0),
		Vector3(0,    sqrt(2.0/3), -sqrt(3)/3),
		Vector3(-0.5, sqrt(2.0/3),  sqrt(3)/6),
		Vector3(0.5,  sqrt(2.0/3),  sqrt(3)/6)
	]
	
	# Rotate tetra_v_inv theta radians about the z axis.
	var cos_theta = cos(theta)
	var sin_theta = sin(theta)
	for i in range(1, 4):
		tetra_v_inv[i] = Vector3(
			tetra_v_inv[i].x * cos_theta - tetra_v_inv[i].z * sin_theta,
			tetra_v_inv[i].y,
			tetra_v_inv[i].x * sin_theta + tetra_v_inv[i].z * cos_theta
		)
	
	# Finally, collide each edge in each tetrahedron with each face in the other tetrahedron.
	# Exclude edges and faces which which do not take the first vertex as member.
	# Only one collision will occur for each edge. That is the vertex's new position,
	# The first vertex of each tetrahedron stays in place.
	# The resulting mesh is the intersection of the tetrahedra.
	
	# Hilariously, this must be done by hand.
	# This is because the order of the vertices in the mesh
	# is arbitrary but always the same.
	
	# Create vertex array. First two vertices are now correct.
	var new_pos = []
	for i in 8:
		new_pos.append(Vector3(0, 0, 0))
	new_pos[0].y = sqrt(2.0/3)
	
	new_pos[2] = segment_intersects_tetra(tetra_v[0], tetra_v[1], tetra_v_inv)
	new_pos[3] = segment_intersects_tetra(tetra_v_inv[0], tetra_v_inv[2], tetra_v)
	new_pos[4] = segment_intersects_tetra(tetra_v[0], tetra_v[2], tetra_v_inv)
	new_pos[5] = segment_intersects_tetra(tetra_v_inv[0], tetra_v_inv[1], tetra_v)
	new_pos[6] = segment_intersects_tetra(tetra_v[0], tetra_v[3], tetra_v_inv)
	new_pos[7] = segment_intersects_tetra(tetra_v_inv[0], tetra_v_inv[3], tetra_v)
	
	# Create MeshDataTool from the existing mesh.
	# We only need to overwrite the vertex positions, each in triplicate.
	var start_mesh = ArrayMesh.new()
	start_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_inst.mesh.surface_get_arrays(0))
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(start_mesh, 0)
	
	#print("--------")
	#print(mdt.get_vertex_count())
	#for i in mdt.get_vertex_count():
		#print(mdt.get_vertex(i))
	#
	#print(mdt.get_edge_count())
	#print(mdt.get_face_count())
	
	for i in 8:
		mdt.set_vertex(i*3  , new_pos[i])
		mdt.set_vertex(i*3+1, new_pos[i])
		mdt.set_vertex(i*3+2, new_pos[i])
	
	#print("--------")
	#print(mdt.get_vertex_count())
	#for i in mdt.get_vertex_count():
		#print(mdt.get_vertex(i))
	#
	#print(mdt.get_edge_count())
	#print(mdt.get_face_count())
	
	start_mesh.clear_surfaces()
	mdt.commit_to_surface(start_mesh)
	mesh_inst.mesh = start_mesh

func _ready():
	my_mat = mesh_inst.get_surface_override_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var timer2 = 0
func _process(delta):
	timer += delta
	timer2 += delta
	
	if timer > update_delay:
		var counter_rotation = counter_rotation_rate * PI / 180 * timer
		theta += counter_rotation
		rotate_y(counter_rotation/2)
		
		timer = 0
	
	my_mat.set_shader_parameter("tex", get_viewport().get_texture())
	my_mat.set_shader_parameter("test", fmod(timer2, 1))
	
	update_mesh()
