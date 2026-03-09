extends Node3D
class_name Spider

@export var ground_offset: float = 0.5
@export var move_speed: float = 3.0
@export var turn_speed: float = 2.0
@export var step_distance: float = 3.0
@export var target_step_offset: float = 20.0
@export var y_smooth_factor: float = 0.0
@export var step_tween_half_speed: float = 0.1

@onready var legs: Array[Dictionary] = [
	{
		"target_marker": %FL_Target,
		"cur_marker": %FL_Cur,
		"ray": %FL_Ray,
	},
	{
		"target_marker": %FR_Target,
		"cur_marker": %FR_Cur,
		"ray": %FR_Ray,
	},
	{
		"target_marker": %BL_Target,
		"cur_marker": %BL_Cur,
		"ray": %BL_Ray,
	},
	{
		"target_marker": %BR_Target,
		"cur_marker": %BR_Cur,
		"ray": %BR_Ray,
	},
]
@onready var step_items_wrap: Node3D = %StepItemsWrap

var leg_pair_index: Array[Array] = [[0,3],[1,2]];
var active_pair: int = 0
var is_stepping: bool = false
var leg_in_action: int = 0
var leg_finished_step: int = 0
var moving_dir_factor: float = 0


func _physics_process(delta: float) -> void:
	process_body_position(delta)
	
	_handle_movement(delta)

	process_step_items_wrap()
	process_steps()


func process_body_position(delta: float) -> void:
	var avg_normal = (legs[0].ray.get_collision_normal() + legs[1].ray.get_collision_normal() + legs[2].ray.get_collision_normal() + legs[3].ray.get_collision_normal()).normalized()
	
	# guard if at start rays doesn't hit the ground
	if avg_normal == Vector3.ZERO:
		avg_normal = Vector3.UP
	else:
		avg_normal = avg_normal.normalized()
	
	var target_basis = _basis_from_normal(avg_normal)
	var from_q = transform.basis.orthonormalized().get_rotation_quaternion()
	var to_q = target_basis.get_rotation_quaternion()
	transform.basis = Basis(from_q.slerp(to_q, move_speed * delta))
	
	var avg = (
		legs[0].cur_marker.global_position + 
		legs[1].cur_marker.global_position + 
		legs[2].cur_marker.global_position + 
		legs[3].cur_marker.global_position
	) / 4

	position.y = lerp(position.y, avg.y + ground_offset, move_speed * y_smooth_factor * delta)


func _handle_movement(delta) -> void:
	moving_dir_factor = Input.get_axis('ui_down', 'ui_up')
	
	translate(Vector3(moving_dir_factor, 0, 0) * move_speed * delta)
	
	var a_dir: float = Input.get_axis('ui_right', 'ui_left')
	rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)


func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)
	return result.orthonormalized()


func process_step_items_wrap() -> void:
	step_items_wrap.rotation.y = rotation.y
	step_items_wrap.global_position = global_position

	if moving_dir_factor != 0:
		step_items_wrap.global_position = global_position + transform.basis.x * moving_dir_factor * target_step_offset
	else:
		step_items_wrap.global_position = global_position


func process_steps() -> void:
	if !is_stepping:
		var leg: Dictionary
		for leg_index in leg_pair_index[active_pair]:
			leg = legs[leg_index]
		
			if abs(leg.cur_marker.global_position.distance_to(leg.target_marker.global_position)) > step_distance:
				is_stepping = true
				leg_in_action += 1
				# insure step animations will start after cur leg pair loop is done
				step.call_deferred(leg)


func step(leg: Dictionary) -> void:
	var half_way: Vector3 = (leg.cur_marker.global_position + leg.target_marker.global_position - Vector3(0, -10, 0)) / 2
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(leg.cur_marker, "global_position", half_way + basis.y, step_tween_half_speed)
	tween.tween_property(leg.cur_marker, "global_position", leg.target_marker.global_position, step_tween_half_speed)
	tween.tween_callback(on_leg_step_finished)


func on_leg_step_finished() -> void:
	leg_finished_step += 1
	if leg_finished_step == leg_in_action:
		leg_finished_step = 0
		leg_in_action = 0
		is_stepping = false
		active_pair = (active_pair + 1) % leg_pair_index.size()
