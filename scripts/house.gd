extends StaticBody3D

## House - buyable, enterable, Sims-style

@export var house_name: String = "Cozy Cottage"
@export var house_price: int = 10000
@export var house_level: int = 1
@export var house_color: Color = Color(1.0, 0.7, 0.29, 1.0)
@export var owner_id: int = -1  # -1 = not owned
@export var house_id: int = 0

var is_player_near: bool = false
var player_in_range: Node3D = null

@onready var house_body: MeshInstance3D = $HouseBody
@onready var roof: MeshInstance3D = $Roof
@onready var door: MeshInstance3D = $Door
@onready var price_label: Label3D = $PriceLabel
@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	_setup_house_mesh()
	_update_price_display()

func _setup_house_mesh() -> void:
	# House body (main box)
	if not house_body:
		house_body = MeshInstance3D.new()
		house_body.name = "HouseBody"
		var box := BoxMesh.new()
		box.size = Vector3(5, 3.5, 6)
		house_body.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = house_color
		mat.roughness = 0.6
		mat.metallic = 0.1
		house_body.material_override = mat
		house_body.position.y = 1.75
		add_child(house_body)
	else:
		house_body.mesh = BoxMesh.new()
		house_body.mesh.size = Vector3(5, 3.5, 6)
		house_body.position.y = 1.75
		var mat := StandardMaterial3D.new()
		mat.albedo_color = house_color
		house_body.material_override = mat

	# Roof
	if not roof:
		roof = MeshInstance3D.new()
		roof.name = "Roof"
		var prism := PrismMesh.new()
		prism.size = Vector3(5.8, 1.5, 6.8)
		roof.mesh = prism
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.65, 0.25, 0.15, 1.0)
		roof_mat.roughness = 0.8
		roof.material_override = roof_mat
		roof.position.y = 4.25
		add_child(roof)

	# Door
	if not door:
		door = MeshInstance3D.new()
		door.name = "Door"
		var door_mesh := BoxMesh.new()
		door_mesh.size = Vector3(1.0, 2.0, 0.1)
		door.mesh = door_mesh
		var door_mat := StandardMaterial3D.new()
		door_mat.albedo_color = Color(0.35, 0.2, 0.1, 1.0)
		door.material_override = door_mat
		door.position = Vector3(0, 1.0, 3.05)
		add_child(door)

	# Windows (2 boxes on sides)
	for i in range(2):
		var window_mesh := MeshInstance3D.new()
		window_mesh.name = "Window_%d" % i
		var w := BoxMesh.new()
		w.size = Vector3(0.8, 0.8, 0.1)
		window_mesh.mesh = w
		var w_mat := StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.8)
		w_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		w_mat.metallic = 0.3
		w_mat.roughness = 0.1
		window_mesh.material_override = w_mat
		var x_pos = -1.5 + i * 3.0
		window_mesh.position = Vector3(x_pos, 2.5, 3.05)
		add_child(window_mesh)

	# Price label (floating above house)
	if not price_label:
		price_label = Label3D.new()
		price_label.name = "PriceLabel"
		price_label.pixel_size = 0.005
		price_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		price_label.position.y = 6.0
		price_label.font_size = 40
		add_child(price_label)

	# Interaction area
	if not interaction_area:
		interaction_area = Area3D.new()
		interaction_area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 4.0
		col.shape = shape
		interaction_area.add_child(col)
		add_child(interaction_area)
		interaction_area.body_entered.connect(_on_player_enter)
		interaction_area.body_exited.connect(_on_player_exit)

func _update_price_display() -> void:
	if owner_id >= 0:
		price_label.text = "Owned by: %s" % _get_owner_name()
		price_label.modulate = Color(0.2, 0.8, 0.2, 1)
	else:
		price_label.text = "%s\n💰 %d" % [house_name, house_price]
		price_label.modulate = Color(1, 1, 1, 1)

func _get_owner_name() -> String:
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if game_manager:
		return game_manager.get_player_name(owner_id)
	return "Unknown"

func _on_player_enter(body: Node3D) -> void:
	if body.has_method("set_player_name"):
		is_player_near = true
		player_in_range = body
		_show_interact_prompt()

func _on_player_exit(body: Node3D) -> void:
	if body.has_method("set_player_name"):
		is_player_near = false
		player_in_range = null
		_hide_interact_prompt()

func _show_interact_prompt() -> void:
	if price_label:
		var current_text = price_label.text
		price_label.text = current_text + "\n[E] Interact"
		price_label.font_size = 48

func _hide_interact_prompt() -> void:
	_update_price_display()

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_near or not player_in_range:
		return

	if event.is_action_pressed("interact"):
		_handle_interaction()

func _handle_interaction() -> void:
	if owner_id >= 0:
		# House is owned - option to enter
		if owner_id == player_in_range.get_instance_id():
			print("Entering my house!")
			_enter_house()
		else:
			print("This house belongs to someone else")
	else:
		# House for sale
		if player_in_range.spend_money(house_price):
			owner_id = player_in_range.get_instance_id()
			house_color = Color(0.2, 0.8, 0.2, 1.0)  # Green = owned
			_update_price_display()
			print("Bought house: ", house_name)
			# Notify multiplayer
			var game_manager = get_node_or_null("/root/Main/GameManager")
			if game_manager:
				game_manager.send_house_purchase(house_id, owner_id)

func _enter_house() -> void:
	# Enter house - simple interior view
	print("Entering house: ", house_name)
	# For now, just show a message
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if game_manager:
		game_manager.show_message("Welcome to %s!" % house_name)

func get_data() -> Dictionary:
	return {
		"id": house_id,
		"name": house_name,
		"price": house_price,
		"owner_id": owner_id,
		"color": house_color,
		"level": house_level,
		"position": {"x": global_position.x, "z": global_position.z}
	}
