extends Camera3D

@export var SPEED: float = 5.5

var _capture_mode: bool = false


func _ready() -> void:
	# hide system mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_capture_mode = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _capture_mode:
			return
		rotation_degrees.y -= event.relative.x * 0.5
		rotation_degrees.x -= event.relative.y * 0.5
		# limit camera rotation by y from -60 to 60
		rotation_degrees.x = clamp(
			rotation_degrees.x,
			-60,
			60
		)
	elif event.is_action_pressed("ui_cancel"):
		# show system mouse on ESC
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_capture_mode = false
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# hide system mouse
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_capture_mode = true


func _physics_process(_delta: float) -> void:
	var inputDirection2D = Input.get_vector(
		"moveLeft",
		"moveRight",
		"moveForward",
		"moveBackward",
	)
	
	var inputDirection3D = Vector3(
		inputDirection2D.x, 0.0, inputDirection2D.y
	)
	
	var direction = transform.basis * inputDirection3D
	
	position.x += direction.x * SPEED
	position.z += direction.z * SPEED
	position.y += direction.y * SPEED
	
