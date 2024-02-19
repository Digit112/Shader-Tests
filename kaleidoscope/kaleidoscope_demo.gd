#@tool
extends MeshInstance3D

@export var timer : float = 0

@export var tex1 : Texture2D
@export var tex2 : Texture2D

var my_mat : ShaderMaterial

func _ready():
	my_mat = get_surface_override_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > 3:
			timer -= 3
	
	var theta = timer/3 * 2*PI
	
	my_mat.set_shader_parameter("theta", theta)
	
	if fmod(timer, 0.3) > 0.15:
		my_mat.set_shader_parameter("base", tex1)
	else:
		my_mat.set_shader_parameter("base", tex2)
