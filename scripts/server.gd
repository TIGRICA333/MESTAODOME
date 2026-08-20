extends SceneTree

## Dedicated Server - runs headless without graphics
## Usage: godot --headless --server scripts/server.gd

const PORT = 7777
const MAX_PLAYERS = 32

var server_peer: ENetMultiplayerPeer

func _init() -> void:
	print("🖥️ SimsWorld Dedicated Server")
	print("Starting on port ", PORT, "...")

	server_peer = ENetMultiplayerPeer.new()
	var err = server_peer.create_server(PORT, MAX_PLAYERS)

	if err != OK:
		push_error("Failed to create server: " + error_string(err))
		quit()
		return

	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("✅ Server started! Waiting for players...")

func _on_peer_connected(id: int) -> void:
	print("Player connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: ", id)
