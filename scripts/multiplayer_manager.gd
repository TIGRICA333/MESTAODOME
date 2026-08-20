extends Node

## Multiplayer Manager - ENet-based internet multiplayer
## Supports up to 32 players in a shared world

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal connection_succeeded()
signal server_full()

const MAX_PLAYERS: int = 32
const SERVER_PORT: int = 7777

var peer: ENetMultiplayerPeer
var is_server: bool = false
var connected_players: Dictionary = {}
var local_peer_id: int = 0

var sync_timer: float = 0.0
var sync_interval: float = 0.05

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Check if we need to auto-connect based on menu selection
	_check_menu_connection()

func _check_menu_connection() -> void:
	var root := get_tree().root
	var mode: String = root.get_meta("mp_mode", "solo")

	if mode == "host":
		var port: int = root.get_meta("mp_port", SERVER_PORT)
		# Apply player name
		var pname: String = root.get_meta("player_name", "Player")
		_apply_player_name(pname)
		host_game(port)
	elif mode == "join":
		var ip: String = root.get_meta("mp_ip", "127.0.0.1")
		var port: int = root.get_meta("mp_port", SERVER_PORT)
		var pname: String = root.get_meta("player_name", "Player")
		_apply_player_name(pname)
		join_game(ip, port)
	# Solo mode = no connection needed

func _apply_player_name(pname: String) -> void:
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_player_name"):
		player.set_player_name(pname)

func _process(delta: float) -> void:
	sync_timer += delta
	if sync_timer >= sync_interval:
		sync_timer = 0.0
		_sync_positions()

## ---- Connection Methods ----

func host_game(port: int = SERVER_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: %s" % error_string(err))
		return err

	multiplayer.multiplayer_peer = peer
	is_server = true
	local_peer_id = 1
	print("🖥️ Hosting game on port ", port)
	return OK

func join_game(address: String = "127.0.0.1", port: int = SERVER_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Failed to connect: %s" % error_string(err))
		return err

	multiplayer.multiplayer_peer = peer
	is_server = false
	print("🔌 Connecting to ", address, ":", port)
	return OK

func disconnect_from_game() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	connected_players.clear()
	is_server = false
	print("🔌 Disconnected from game")

## ---- Peer Callbacks ----

func _on_peer_connected(id: int) -> void:
	print("Player connected: ", id)
	connected_players[id] = {
		"name": "Player_%d" % id,
		"position": Vector3.ZERO,
		"rotation": 0.0,
		"color": Color(randf(), randf(), randf())
	}
	player_connected.emit(id)

	if is_server:
		_send_world_state(id)

func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: ", id)
	connected_players.erase(id)
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.remove_remote_player(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	print("✅ Connected! My ID: ", local_peer_id)
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	print("❌ Connection failed!")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("❌ Server disconnected!")
	connected_players.clear()
	connection_failed.emit()

## ---- RPC Methods ----

@rpc("any_peer", "reliable")
func sync_player_data(peer_id: int, data: Dictionary) -> void:
	if peer_id == local_peer_id:
		return
	connected_players[peer_id] = data
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.update_remote_player(peer_id, data)

@rpc("any_peer", "unreliable")
func sync_position(peer_id: int, pos: Vector3, rot: float) -> void:
	if peer_id == local_peer_id:
		return
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.update_remote_player_position(peer_id, pos, rot)

@rpc("authority", "reliable")
func sync_house_purchase(house_id: int, owner_id: int) -> void:
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.update_house_owner(house_id, owner_id)

@rpc("authority", "reliable")
func sync_player_join(peer_id: int, data: Dictionary) -> void:
	connected_players[peer_id] = data
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.spawn_remote_player(peer_id, data)

@rpc("authority", "reliable")
func sync_player_leave(peer_id: int) -> void:
	connected_players.erase(peer_id)
	var world = get_node_or_null("/root/Main/World")
	if world:
		world.remove_remote_player(peer_id)

## ---- Sending Methods ----

func send_player_position(pos: Vector3, rot: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	sync_position.rpc(local_peer_id, pos, rot)

func send_player_data(data: Dictionary) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	sync_player_data.rpc(local_peer_id, data)

func send_house_purchase(house_id: int, owner_id: int) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if is_server:
		sync_house_purchase.rpc(house_id, owner_id)
	else:
		sync_house_purchase.rpc_id(1, house_id, owner_id)

func _send_world_state(target_peer: int) -> void:
	for pid in connected_players:
		sync_player_join.rpc_id(target_peer, pid, connected_players[pid])

func _sync_positions() -> void:
	pass

## ---- Utility ----

func is_connected_to_server() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.get_connection_status() == Multiplayer.CONNECTION_CONNECTED

func get_connected_count() -> int:
	return connected_players.size() + 1

func get_player_list() -> Array:
	var list := []
	for pid in connected_players:
		list.append(connected_players[pid].get("name", "Player_%d" % pid))
	return list

func is_host() -> bool:
	return is_server
