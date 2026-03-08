extends RayCast3D

@export var step_target: Marker3D


func _physics_process(_delta):
	if is_colliding():
		step_target.global_position = get_collision_point()
