extends Node3D

## Main Scene Controller

func _ready() -> void:
	print("[Game] Starting Build Your House...")
	_setup_environment()
	print("[Game] Environment OK")
	_setup_world()
	print("[Game] World OK")
	_setup_player()
	print("[Game] Player OK")
	_setup_ui()
	print("[Game] UI OK")
	_setup_game_manager()
	print("[Game] GameManager OK")
	_setup_multiplayer()
	print("[Game] Multiplayer OK")
	_start_game()

func _setup_environment() -> void:
	# Sky background
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	add_child(world_env)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.81, 0.92, 1)  # Light blue sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.85, 0.8, 1)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.fog_enabled = false  # Disable fog for clarity
	world_env.environment = env

	# Sun
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_color = Color(1.0, 0.95, 0.85, 1)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

func _setup_world() -> void:
	var world := Node3D.new()
	world.name = "World"
	world.set_script(load("res://scripts/world.gd"))
	add_child(world)

func _setup_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.5, 0)

	# Collision shape
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.2
	col.shape = shape
	player.add_child(col)

	# Add camera BEFORE setting script (so @onready finds it)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 4, 6)
	camera.rotation.x = deg_to_rad(-35)
	camera.fov = 60.0
	camera.far = 200.0
	camera.set_script(load("res://scripts/camera_controller.gd"))
	player.add_child(camera)

	# Set player script AFTER camera is added
	player.set_script(load("res://scripts/player.gd"))
	add_child(player)

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

func _start_game() -> void:
	print("========================================")
	print("  🏠 Build Your House v1.1.0")
	print("  WASD - Move | Mouse - Look")
	print("  E - Interact | Shift - Run")
	print("  ESC - Menu")
	print("========================================")

	var ui = get_node_or_null("UI")
	if ui and ui.has_method("show_message"):
		ui.show_message("Welcome to Build Your House!")
