extends Node3D

@onready var parent : Node3D = get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation.y = -parent.theta + PI/3
