extends Node3D

## Main Scene Controller - creates all game systems in code

func _ready() -> void:
	_setup_environment()
	_setup_world()
	_setup_player()
	_setup_ui()
	_setup_game_manager()
	_setup_multiplayer()
	_setup_updater()
	_start_game()

func _setup_environment() -> void:
	# World environment
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	add_child(world_env)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.75, 0.85, 1.0, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.85, 0.8, 1)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.9, 1.0, 1)
	env.fog_density = 0.003
	world_env.environment = env

	# Directional light
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_color = Color(1.0, 0.95, 0.85, 1)
	light.light_energy = 1.2
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 80.0
	add_child(light)

func _setup_world() -> void:
	var world := Node3D.new()
	world.name = "World"
	world.set_script(load("res://scripts/world.gd"))
	add_child(world)

func _setup_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.5, 0)

	# Collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.2
	col.shape = shape
	player.add_child(col)

	player.set_script(load("res://scripts/player.gd"))
	add_child(player)

	# Camera
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 4, 6)
	camera.rotation.x = deg_to_rad(-35)
	camera.fov = 60.0
	camera.far = 200.0
	camera.set_script(load("res://scripts/camera_controller.gd"))
	player.add_child(camera)

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(load("res://scripts/ui.gd"))
	add_child(ui)

func _setup_game_manager() -> void:
	var gm := Node.new()
	gm.name = "GameManager"
	gm.set_script(load("res://scripts/game_manager.gd"))
	add_child(gm)

func _setup_multiplayer() -> void:
	var mp := Node.new()
	mp.name = "MultiplayerController"
	mp.set_script(load("res://scripts/multiplayer_manager.gd"))
	add_child(mp)

func _setup_updater() -> void:
	var updater := Node.new()
	updater.name = "AutoUpdater"
	updater.set_script(load("res://scripts/auto_updater.gd"))
	add_child(updater)

	var dialog := CanvasLayer.new()
	dialog.name = "UpdateDialog"
	dialog.set_script(load("res://scripts/update_dialog.gd"))
	add_child(dialog)

	# Connect updater signals
	updater.update_available.connect(_on_update_available)
	updater.update_check_failed.connect(_on_update_check_failed)

func _on_update_available(current: String, new_version: String, url: String) -> void:
	var dialog = get_node_or_null("UpdateDialog")
	if dialog:
		dialog.show_update_dialog(current, new_version, url)

func _on_update_check_failed(error: String) -> void:
	print("[Updater] Check failed: ", error)

func _start_game() -> void:
	print("🌍 Welcome to Build Your House!")
	print("🎮 WASD to move, Mouse to look, E to interact, Shift to sprint")
	print("📋 ESC for menu")

	var ui = get_node_or_null("UI")
	if ui and ui.has_method("show_message"):
		ui.show_message("Welcome to Build Your House!")
