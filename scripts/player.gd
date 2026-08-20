extends CharacterBody3D

## Player controller - WASD movement, camera follow

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var rotation_speed: float = 8.0
@export var gravity: float = 20.0

var target_rotation: float = 0.0
var is_sprinting: bool = false
var player_name: String = "Player"
var money: int = 5000
var owned_houses: Array = []
var player_color: Color = Color(0.31, 0.80, 0.77, 1.0)

var camera: Camera3D
var body_mesh: MeshInstance3D
var name_label: Label3D

func _ready() -> void:
	camera = get_node_or_null("Camera")
	_setup_character_mesh()
	_setup_name_label()

func _physics_process(delta: float) -> void:
	if not camera:
		camera = get_node_or_null("Camera")
		if not camera:
			return

	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle sprint
	is_sprinting = Input.is_action_pressed("sprint")
	var speed: float = sprint_speed if is_sprinting else walk_speed

	# Get movement input
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")
	input_dir = input_dir.normalized()

	# Camera-relative movement
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir := (forward * -input_dir.y + right * input_dir.x).normalized()

	if move_dir.length() > 0.1:
		target_rotation = atan2(move_dir.x, move_dir.z)
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10)

	move_and_slide()
	_send_position_update()

func _send_position_update() -> void:
	var mp = get_node_or_null("/root/Main/MultiplayerController")
	if mp and mp.has_method("is_connected_to_server") and mp.is_connected_to_server():
		mp.send_player_position(global_position, rotation.y)

func _setup_character_mesh() -> void:
	if body_mesh:
		return

	# Torso
	var body := MeshInstance3D.new()
	body.name = "BodyMesh"
	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 0.8
	body.mesh = torso
	var mat := StandardMaterial3D.new()
	mat.albedo_color = player_color
	mat.roughness = 0.7
	body.material_override = mat
	body.position.y = 0.2
	add_child(body)
	body_mesh = body

	# Head
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 0.85
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.94, 0.82, 0.73, 1.0)
	head_mat.roughness = 0.6
	head.material_override = head_mat
	add_child(head)

	# Hair
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.24
	hair_mesh.height = 0.3
	hair.mesh = hair_mesh
	hair.position.y = 0.95
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.25, 0.15, 0.08, 1.0)
	hair.material_override = hair_mat
	add_child(hair)

	# Arms
	for i in range(2):
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.08
		arm_mesh.height = 0.5
		arm.mesh = arm_mesh
		arm.position = Vector3(-0.4 + i * 0.8, 0.15, 0)
		arm.material_override = body.get_material_override()
		add_child(arm)

	# Legs
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.2, 0.2, 0.5, 1.0)
	for i in range(2):
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.1
		leg_mesh.height = 0.5
		leg.mesh = leg_mesh
		leg.position = Vector3(-0.15 + i * 0.3, -0.55, 0)
		leg.material_override = leg_mat
		add_child(leg)

func _setup_name_label() -> void:
	var label3d := Label3D.new()
	label3d.name = "NameLabel"
	label3d.text = player_name
	label3d.pixel_size = 0.005
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.position.y = 1.3
	label3d.font_size = 32
	label3d.modulate = Color(1, 1, 1, 0.9)
	add_child(label3d)
	name_label = label3d

func set_player_name(new_name: String) -> void:
	player_name = new_name
	if name_label:
		name_label.text = new_name

func set_player_color(new_color: Color) -> void:
	player_color = new_color
	if body_mesh:
		body_mesh.material_override.albedo_color = new_color

func add_money(amount: int) -> void:
	money += amount
	_update_ui()

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		_update_ui()
		return true
	return false

func buy_house(house_data: Dictionary) -> void:
	if spend_money(house_data.get("price", 0)):
		owned_houses.append(house_data)
		print("Bought house: ", house_data.get("name", "Unknown"))
		_update_ui()

func _update_ui() -> void:
	var ui = get_node_or_null("/root/Main/UI")
	if ui and ui.has_method("update_player_info"):
		ui.update_player_info(player_name, money, owned_houses.size())
