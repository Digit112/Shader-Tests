extends MeshInstance3D

# Acquire a rendering device and compile the glsl code for it.
var rd : RenderingDevice
@onready var compute_file : RDShaderFile = load("res://gravity/gravity.glsl")
var shader_spirv : RDShaderSPIRV
var compute_comp : RID

# Will be used for storing vertex positions.
var positions : PackedFloat32Array
var velocities : PackedFloat32Array

var positions_byt : PackedByteArray
var velocities_byt : PackedByteArray

# Used for transfer of data between CPU and GPU
var positions_buf : RID
var velocities_buf : RID

# Used for bindings between compute kernel params and buffers
var positions_uni : RDUniform
var velocities_uni : RDUniform

# Create an object to hold the parameters for the compute kernel
var uniform_set : RID

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
	
	# Initialize data
	positions = PackedFloat32Array()
	velocities = PackedFloat32Array()
	
	for i in range(8):
		positions.append(randf_range(0, 1))
		positions.append(randf_range(0, 1))
		
		velocities.append(randf_range(-0.2, 0.2))
		velocities.append(randf_range(-0.2, 0.2))
	
	positions_byt = positions.to_byte_array()
	velocities_byt = velocities.to_byte_array()
	
	# Create a storage buffer that can hold our float values.
	positions_buf = rd.storage_buffer_create(positions_byt.size(), positions_byt)
	velocities_buf = rd.storage_buffer_create(velocities_byt.size(), velocities_byt)
	
	# Create uniforms to assign buffers to the rendering device
	positions_uni = RDUniform.new()
	positions_uni.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	positions_uni.binding = 0 # this needs to match the "binding" in our shader file
	positions_uni.add_id(positions_buf)
	
	velocities_uni = RDUniform.new()
	velocities_uni.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	velocities_uni.binding = 1 # this needs to match the "binding" in our shader file
	velocities_uni.add_id(velocities_buf)
	
	# the last parameter (the 0) needs to match the "set" in our shader file
	uniform_set = rd.uniform_set_create([positions_uni, velocities_uni], compute_comp, 0)

func submit_kernel_job():
	var pipeline = rd.compute_pipeline_create(compute_comp)
	var compute_list = rd.compute_list_begin()
	
	# Create a compute pipeline
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 2, 1, 1)
	rd.compute_list_end()
	
	rd.submit()

func sync_kernel_job():
	rd.sync()
	
	# Read back the data from the buffer
	velocities_byt = rd.buffer_get_data(velocities_buf)
	positions_byt = rd.buffer_get_data(positions_buf)
	
	positions = positions_byt.to_float32_array()

func _physics_process(_delta):
	my_mat.set_shader_parameter("positions", positions)
	
	submit_kernel_job()
	sync_kernel_job()
