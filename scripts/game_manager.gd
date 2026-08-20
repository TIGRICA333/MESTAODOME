extends Node

## Game Manager - central game state, economy, day/night

signal money_changed(new_amount: int)
signal house_bought(house_data: Dictionary)
signal message_displayed(text: String)
signal day_started(day: int)

var current_day: int = 1
var game_time: float = 0.0  # 0-24 hours
var day_duration: float = 120.0  # seconds per in-game day

var player_data: Dictionary = {
	"name": "Player",
	"money": 5000,
	"houses": [],
	"inventory": [],
	"needs": {
		"hunger": 100,
		"energy": 100,
		"fun": 100,
		"hygiene": 100,
		"social": 100
	}
}

# Economy
var job_salary: int = 500
var rent_cost: int = 200

func _ready() -> void:
	# Start the day cycle
	pass

func _process(delta: float) -> void:
	# Update game time
	game_time += (delta * 24.0) / day_duration
	if game_time >= 24.0:
		game_time = 0.0
		_on_new_day()

	# Update needs (decay over time)
	_update_needs(delta)

func _on_new_day() -> void:
	current_day += 1
	day_started.emit(current_day)
	print("Day ", current_day, " begins!")

	# Pay salary
	add_money(job_salary)
	show_message("Day %d - Salary: +%d$" % [current_day, job_salary])

	# Charge rent for owned houses
	for house_id in player_data["houses"]:
		spend_money(rent_cost)

func _update_needs(delta: float) -> void:
	var decay_rate: float = 0.5  # per second
	player_data["needs"]["hunger"] = max(0, player_data["needs"]["hunger"] - decay_rate * delta)
	player_data["needs"]["energy"] = max(0, player_data["needs"]["energy"] - decay_rate * delta * 0.5)
	player_data["needs"]["fun"] = max(0, player_data["needs"]["fun"] - decay_rate * delta * 0.3)
	player_data["needs"]["hygiene"] = max(0, player_data["needs"]["hygiene"] - decay_rate * delta * 0.2)

func add_money(amount: int) -> void:
	player_data["money"] += amount
	money_changed.emit(player_data["money"])

func spend_money(amount: int) -> bool:
	if player_data["money"] >= amount:
		player_data["money"] -= amount
		money_changed.emit(player_data["money"])
		return true
	return false

func get_money() -> int:
	return player_data["money"]

func buy_house(house_data: Dictionary) -> bool:
	if spend_money(house_data.get("price", 0)):
		player_data["houses"].append(house_data.get("id", -1))
		house_bought.emit(house_data)
		show_message("Bought: %s for %d$" % [house_data.get("name", "House"), house_data.get("price", 0)])
		return true
	return false

func fulfill_need(need_name: String, amount: float) -> void:
	if need_name in player_data["needs"]:
		player_data["needs"][need_name] = min(100, player_data["needs"][need_name] + amount)

func get_need(need_name: String) -> float:
	return player_data["needs"].get(need_name, 0)

func show_message(text: String) -> void:
	message_displayed.emit(text)
	print("[Game] ", text)

func get_time_string() -> String:
	var hours := int(game_time)
	var minutes := int((game_time - hours) * 60)
	return "%02d:%02d" % [hours, minutes]

func is_multiplayer_active() -> bool:
	var mp = get_node_or_null("/root/Main/MultiplayerManager")
	return mp != null and mp.is_connected_to_server()

func get_player_name(id: int) -> String:
	return "Player_%d" % id
