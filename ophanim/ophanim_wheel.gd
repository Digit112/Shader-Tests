#@tool
extends Node3D

var mat : ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh : MeshInstance3D = get_child(0)
	mat = mesh.get_surface_override_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var timer : float = 0
func _process(delta):
	timer += delta
	if timer > 6:
		timer -= 6
	
	var theta = timer / 6 * 2 * PI
	var cth = cos(theta)
	var sth = sin(theta)
	
	mat.set_shader_parameter("C", Vector2(
		0.6*cth,
		0.6*sth
	))

	rotate_object_local(Vector3(1, 0, 0), delta / 8 * 2 * PI)
