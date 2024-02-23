extends MeshInstance3D

# Acquire a rendering device and compile the glsl code for it.
var rd : RenderingDevice
@onready var compute_file : RDShaderFile = load("res://conway_gol/conway.glsl")
var shader_spirv : RDShaderSPIRV
var compute_comp : RID

# Will be used for storing vertex positions.
var grid : PackedInt32Array
var out_grid : PackedInt32Array

var grid_byt : PackedByteArray
var out_grid_byt : PackedByteArray

# Used for transfer of data between CPU and GPU
var grid_buf : RID
var out_grid_buf : RID

# Used for bindings between compute kernel params and buffers
var grid_uni : RDUniform
var out_grid_uni : RDUniform

# Create an object to hold the parameters for the compute kernel
var uniform_set : RID

# Size of the game of life grid. VALUES MUST ALSO BE UPDATED IN THE GDSHADER.
@export var grid_width : int
@export var grid_height : int

var rng = RandomNumberGenerator.new()

var my_mat : ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready():
	my_mat = get_surface_override_material(0)
	
	rd = RenderingServer.create_local_rendering_device()
	shader_spirv = compute_file.get_spirv()
	compute_comp = rd.shader_create_from_spirv(shader_spirv)
	
	# Debug
	print("Running compute kernel on: " + rd.get_device_vendor_name() + ": " + rd.get_device_name())
	print("Compilation report: " + str(compute_file.base_error))
	print("Bytecode report: " + str(shader_spirv.compile_error_compute))
	
	grid = PackedInt32Array()
	out_grid = PackedInt32Array()
	for x in range(grid_width):
		for y in range(grid_height):
			grid.append(0)
			out_grid.append(0)
	
	for i in range(int(grid_width*grid_height*0.2)):
		grid[rng.randi_range(0, grid_width*grid_height-1)] = 1
	
	grid_byt = grid.to_byte_array()
	out_grid_byt = out_grid.to_byte_array()
	
	# Create a storage buffer that can hold our float values.
	print("Creating " + str(grid_width) + "x" + str(grid_height) + " grid.")
	grid_buf = rd.storage_buffer_create(grid_byt.size(), grid_byt)
	out_grid_buf = rd.storage_buffer_create(out_grid_byt.size(), out_grid_byt)
	
	# Create uniforms to assign buffers to the rendering device
	grid_uni = RDUniform.new()
	grid_uni.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	grid_uni.binding = 0 # this needs to match the "binding" in our shader file
	grid_uni.add_id(grid_buf)
	
	out_grid_uni = RDUniform.new()
	out_grid_uni.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	out_grid_uni.binding = 1 # this needs to match the "binding" in our shader file
	out_grid_uni.add_id(out_grid_buf)
	
	# the last parameter (the 0) needs to match the "set" in our shader file
	uniform_set = rd.uniform_set_create([grid_uni, out_grid_uni], compute_comp, 0)

func submit_kernel_job():
	var pipeline = rd.compute_pipeline_create(compute_comp)
	var compute_list = rd.compute_list_begin()
	
	# Create a compute pipeline
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, grid_width/4, grid_height/4, 1)
	rd.compute_list_end()
	
	rd.submit()

func sync_kernel_job():
	rd.sync()
	grid_byt = rd.buffer_get_data(out_grid_buf)
	rd.buffer_update(grid_buf, 0, grid_byt.size(), grid_byt)
	
	grid = grid_byt.to_int32_array()

# Called every frame. 'delta' is the elapsed time since the previous frame.
var timer : float = 0
func _physics_process(delta):
	timer += delta;
	
	if timer > 0.5:
		timer -= 0.5
		#var dbg : String

		#dbg = ""
		#for y in range(grid_height):
			#for x in range(grid_width):
				#dbg = dbg + str(grid[y*grid_width + x])
			#dbg = dbg + "\n"
		#print(dbg)
		#
		#print("Job...")
		submit_kernel_job()
		sync_kernel_job()
		my_mat.set_shader_parameter("grid", grid)
