extends Node3D

## World Builder - procedurally places houses, trees, NPCs
## and manages remote player avatars in multiplayer

# World configuration
const WORLD_SIZE: int = 100
const HOUSE_SPACING: int = 20
const TREE_COUNT: int = 80

# Preloaded scenes will be created in code
var remote_players: Dictionary = {}  # peer_id -> MeshInstance3D
var houses: Array = []
var remote_player_container: Node3D

# House data for the world
var house_templates: Array = [
	{"name": "Cozy Cottage", "price": 8000, "color": Color(1.0, 0.7, 0.29, 1.0), "level": 1},
	{"name": "Family Home", "price": 15000, "color": Color(0.6, 0.8, 1.0, 1.0), "level": 2},
	{"name": "Modern Villa", "price": 25000, "color": Color(0.9, 0.9, 0.95, 1.0), "level": 3},
	{"name": "Penthouse", "price": 50000, "color": Color(0.3, 0.1, 0.4, 1.0), "level": 4},
	{"name": "Country House", "price": 12000, "color": Color(0.85, 0.65, 0.45, 1.0), "level": 2},
	{"name": "Lake Cabin", "price": 10000, "color": Color(0.55, 0.35, 0.2, 1.0), "level": 1},
	{"name": "Town House", "price": 18000, "color": Color(0.95, 0.85, 0.7, 1.0), "level": 2},
	{"name": "Garden House", "price": 9500, "color": Color(0.6, 0.9, 0.6, 1.0), "level": 1},
	{"name": "Sunset Villa", "price": 30000, "color": Color(1.0, 0.5, 0.3, 1.0), "level": 3},
	{"name": "Mountain Lodge", "price": 22000, "color": Color(0.4, 0.25, 0.15, 1.0), "level": 2},
]

func _ready() -> void:
	remote_player_container = Node3D.new()
	remote_player_container.name = "RemotePlayers"
	add_child(remote_player_container)

	generate_world()

func generate_world() -> void:
	_generate_houses()
	_generate_trees()
	_generate_decorations()

## ---- House Generation ----

func _generate_houses() -> void:
	var house_id: int = 0
	var positions := _calculate_house_positions()

	for pos in positions:
		var template: Dictionary = house_templates[house_id % house_templates.size()]
		var house := _create_house(pos, template, house_id)
		add_child(house)
		houses.append(house)
		house_id += 1

func _calculate_house_positions() -> Array:
	var positions := []

	# Houses along the main road (left side)
	for i in range(5):
		var x := -30.0 + i * 15.0
		positions.append(Vector3(x, 0, -25))

	# Houses along the main road (right side)
	for i in range(5):
		var x := -30.0 + i * 15.0
		positions.append(Vector3(x, 0, 25))

	return positions

func _create_house(pos: Vector3, template: Dictionary, id: int) -> StaticBody3D:
	var house := StaticBody3D.new()
	house.name = "House_%d" % id
	house.position = pos

	# Set house properties
	house.set("house_name", template.get("name", "House"))
	house.set("house_price", template.get("price", 10000))
	house.set("house_color", template.get("color", Color.WHITE))
	house.set("house_level", template.get("level", 1))
	house.set("house_id", id)

	# Load and attach house script
	var script = load("res://scripts/house.gd")
	house.set_script(script)

	return house

## ---- Tree Generation ----

func _generate_trees() -> void:
	for i in range(TREE_COUNT):
		var x := randf_range(-WORLD_SIZE / 2.0, WORLD_SIZE / 2.0)
		var z := randf_range(-WORLD_SIZE / 2.0, WORLD_SIZE / 2.0)

		# Don't place on roads or houses
		if abs(x) < 5 or abs(z) < 5:  # Road area
			continue

		var tree := _create_tree(Vector3(x, 0, z), randi_range(0, 2))
		add_child(tree)

func _create_tree(pos: Vector3, tree_type: int) -> Node3D:
	var tree := Node3D.new()
	tree.name = "Tree"
	tree.position = pos

	# Trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.15
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 2.0 + randf() * 1.5
	trunk.mesh = trunk_mesh
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.12, 1.0)
	trunk_mat.roughness = 0.9
	trunk.material_override = trunk_mat
	trunk.position.y = trunk_mesh.height / 2.0
	tree.add_child(trunk)

	# Foliage
	var foliage := MeshInstance3D.new()
	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 1.0 + randf() * 0.8
	foliage_mesh.height = foliage_mesh.radius * 2.5
	foliage.mesh = foliage_mesh
	var foliage_mat := StandardMaterial3D.new()

	# Different green shades
	var greens := [
		Color(0.2, 0.65, 0.25, 1.0),
		Color(0.3, 0.75, 0.2, 1.0),
		Color(0.15, 0.55, 0.3, 1.0)
	]
	foliage_mat.albedo_color = greens[tree_type % greens.size()]
	foliage_mat.roughness = 0.8
	foliage.material_override = foliage_mat
	foliage.position.y = trunk_mesh.height + foliage_mesh.radius * 0.5
	tree.add_child(foliage)

	# Collision for trees (invisible)
	var col := StaticBody3D.new()
	col.name = "TreeCollider"
	var col_shape := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 1.0
	col_shape.shape = shape
	col.add_child(col_shape)
	col.position.y = 0.5
	tree.add_child(col)

	return tree

## ---- Decorations ----

func _generate_decorations() -> void:
	# Flowers / bushes near houses
	for i in range(40):
		var x := randf_range(-WORLD_SIZE / 2.0, WORLD_SIZE / 2.0)
		var z := randf_range(-WORLD_SIZE / 2.0, WORLD_SIZE / 2.0)
		if abs(x) < 5 or abs(z) < 5:
			continue
		_create_bush(Vector3(x, 0, z))

func _create_bush(pos: Vector3) -> void:
	var bush := MeshInstance3D.new()
	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 0.3 + randf() * 0.3
	bush.mesh = bush_mesh
	var mat := StandardMaterial3D.new()

	# Random bush colors
	var colors := [
		Color(0.2, 0.6, 0.2, 1.0),
		Color(0.15, 0.5, 0.25, 1.0),
		Color(0.25, 0.7, 0.15, 1.0),
		Color(0.8, 0.2, 0.3, 1.0),  # Flower bush
		Color(0.9, 0.7, 0.2, 1.0),  # Yellow flowers
	]
	mat.albedo_color = colors[randi() % colors.size()]
	mat.roughness = 0.8
	bush.material_override = mat
	bush.position = pos + Vector3(0, bush_mesh.radius * 0.7, 0)
	add_child(bush)

## ---- Remote Player Management ----

func spawn_remote_player(peer_id: int, data: Dictionary) -> void:
	if remote_players.has(peer_id):
		return

	var player := CharacterBody3D.new()
	player.name = "RemotePlayer_%d" % peer_id

	# Create body
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	body.position.y = 0.2

	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.get("color", Color(0.8, 0.3, 0.3, 1.0))
	mat.roughness = 0.7
	body.material_override = mat
	player.add_child(body)

	# Name label
	var label := Label3D.new()
	label.text = data.get("name", "Player_%d" % peer_id)
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.3
	label.font_size = 32
	player.add_child(label)

	# Head
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head.mesh = head_mesh
	head.position.y = 0.85
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.94, 0.82, 0.73, 1.0)
	head.material_override = head_mat
	player.add_child(head)

	# Position
	var pos: Vector3 = data.get("position", Vector3.ZERO)
	if pos is Vector3:
		player.global_position = pos
	elif pos is Dictionary:
		player.global_position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))

	remote_player_container.add_child(player)
	remote_players[peer_id] = player

func update_remote_player(peer_id: int, data: Dictionary) -> void:
	if not remote_players.has(peer_id):
		spawn_remote_player(peer_id, data)
		return

	var player = remote_players[peer_id]
	var pos = data.get("position", null)
	if pos is Vector3:
		player.global_position = pos
	elif pos is Dictionary:
		player.global_position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))

func update_remote_player_position(peer_id: int, pos: Vector3, rot: float) -> void:
	if not remote_players.has(peer_id):
		return
	var player = remote_players[peer_id]
	# Smooth interpolation (lerp)
	player.global_position = player.global_position.lerp(pos, 0.3)
	player.rotation.y = rot

func remove_remote_player(peer_id: int) -> void:
	if remote_players.has(peer_id):
		remote_players[peer_id].queue_free()
		remote_players.erase(peer_id)

func update_house_owner(house_id: int, owner_id: int) -> void:
	for house in houses:
		if house.get("house_id", -1) == house_id:
			house.set("owner_id", owner_id)
			house.set("house_color", Color(0.2, 0.8, 0.2, 1.0))
			break
