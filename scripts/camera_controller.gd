extends Camera3D

## Sims-style third person camera
## Follows player, mouse to rotate view, scroll to zoom

@export var follow_speed: float = 8.0
@export var rotation_speed: float = 0.003
@export var zoom_speed: float = 1.0
@export var min_distance: float = 3.0
@export var max_distance: float = 15.0
@export var min_pitch: float = -80.0
@export var max_pitch: float = -15.0
@export var pitch: float = -35.0
@export var yaw: float = 0.0
@export var distance: float = 8.0

var target: Node3D
var is_rotating: bool = false

func _ready() -> void:
	# Capture mouse for rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	target = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	# Right mouse button to rotate camera
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Scroll to zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_speed, min_distance, max_distance)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_speed, min_distance, max_distance)

	if event is InputEventMouseMotion and is_rotating:
		yaw -= event.relative.x * rotation_speed
		pitch = clamp(pitch + event.relative.y * rotation_speed * 50, min_pitch, max_pitch)

func _process(delta: float) -> void:
	if not target:
		return

	# Calculate camera position
	var target_pos := target.global_position + Vector3(0, 1.5, 0)

	# Spherical coordinates
	var offset := Vector3.ZERO
	offset.x = distance * cos(deg_to_rad(pitch)) * sin(yaw)
	offset.y = -distance * sin(deg_to_rad(pitch))
	offset.z = distance * cos(deg_to_rad(pitch)) * cos(yaw)

	var desired_pos := target_pos + offset

	# Smooth follow
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Look at target
	look_at(target_pos, Vector3.UP)
