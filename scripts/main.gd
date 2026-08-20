extends Node3D

## Main Scene Controller - initializes and connects all game systems

@onready var world: Node3D = $World
@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera
@onready var ui: CanvasLayer = $UI
@onready var game_manager: Node = $GameManager
@onready var multiplayer_manager: Node = $MultiplayerController

# Scene creation helpers
func _ready() -> void:
	# Create child nodes that don't exist in scene file
	_setup_scene_tree()
	_connect_signals()
	_start_game()

func _setup_scene_tree() -> void:
	# World node
	if not world:
		world = Node3D.new()
		world.name = "World"
		world.set_script(load("res://scripts/world.gd"))
		add_child(world)

	# Player
	if not player:
		player = CharacterBody3D.new()
		player.name = "Player"
		player.position = Vector3(0, 0.5, 0)
		player.set_script(load("res://scripts/player.gd"))
		add_child(player)

		# Camera
		camera = Camera3D.new()
		camera.name = "Camera"
		camera.position = Vector3(0, 4, 6)
		camera.rotation.x = deg_to_rad(-35)
		camera.set_script(load("res://scripts/camera_controller.gd"))
		player.add_child(camera)

	# UI
	if not ui:
		ui = CanvasLayer.new()
		ui.name = "UI"
		ui.set_script(load("res://scripts/ui.gd"))
		add_child(ui)

	# Game Manager
	if not game_manager:
		game_manager = Node.new()
		game_manager.name = "GameManager"
		game_manager.set_script(load("res://scripts/game_manager.gd"))
		add_child(game_manager)

	# Multiplayer Manager
	if not multiplayer_manager:
		multiplayer_manager = Node.new()
		multiplayer_manager.name = "MultiplayerController"
		multiplayer_manager.set_script(load("res://scripts/multiplayer_manager.gd"))
		add_child(multiplayer_manager)

func _connect_signals() -> void:
	# Connect multiplayer signals
	if multiplayer_manager:
		multiplayer_manager.player_connected.connect(_on_player_connected)
		multiplayer_manager.player_disconnected.connect(_on_player_disconnected)
		multiplayer_manager.connection_succeeded.connect(_on_connection_succeeded)

func _start_game() -> void:
	print("🌍 Welcome to SimsWorld!")
	print("🎮 WASD to move, Mouse to look, E to interact, Shift to sprint")
	print("📋 ESC for menu")

	if ui:
		ui.show_message("Welcome to SimsWorld! Use WASD to move.")

## ---- Multiplayer Connection UI ----

func show_connection_dialog(is_hosting: bool) -> void:
	# Simple connection dialog using input
	var dialog := AcceptDialog.new()
	dialog.name = "ConnectionDialog"
	dialog.title = "Host Game" if is_hosting else "Join Game"
	dialog.size = Vector2(400, 200)

	var vbox := VBoxContainer.new()
	dialog.add_child(vbox)

	if is_hosting:
		var port_input := LineEdit.new()
		port_input.text = "7777"
		port_input.placeholder_text = "Port"
		vbox.add_child(port_input)

		var host_btn := Button.new()
		host_btn.text = "🖥️ Host Game"
		host_btn.pressed.connect(func():
			var port := int(port_input.text) if port_input.text.is_valid_int() else 7777
			multiplayer_manager.host_game(port)
			dialog.queue_free()
		)
		vbox.add_child(host_btn)
	else:
		var ip_input := LineEdit.new()
		ip_input.text = "127.0.0.1"
		ip_input.placeholder_text = "Server IP"
		vbox.add_child(ip_input)

		var port_input := LineEdit.new()
		port_input.text = "7777"
		port_input.placeholder_text = "Port"
		vbox.add_child(port_input)

		var join_btn := Button.new()
		join_btn.text = "🔌 Join Game"
		join_btn.pressed.connect(func():
			multiplayer_manager.join_game(ip_input.text, int(port_input.text))
			dialog.queue_free()
		)
		vbox.add_child(join_btn)

	add_child(dialog)
	dialog.popup_centered()

## ---- Signal Handlers ----

func _on_player_connected(peer_id: int) -> void:
	if ui:
		ui.show_message("Player %d joined!" % peer_id)
		var mp = get_node_or_null("/root/Main/MultiplayerController")
		if mp:
			ui.update_player_list(mp.get_player_list())

func _on_player_disconnected(peer_id: int) -> void:
	if ui:
		ui.show_message("Player %d left" % peer_id)
		var mp = get_node_or_null("/root/Main/MultiplayerController")
		if mp:
			ui.update_player_list(mp.get_player_list())

func _on_connection_succeeded() -> void:
	if ui:
		ui.show_message("Connected to server!")
		var mp = get_node_or_null("/root/Main/MultiplayerController")
		if mp:
			ui.update_player_list(mp.get_player_list())
