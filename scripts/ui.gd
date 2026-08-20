extends CanvasLayer

## Game UI - HUD overlay showing player info, needs, and menus

var money_label: Label
var time_label: Label
var day_label: Label
var needs_container: VBoxContainer
var message_label: Label
var message_timer: float = 0.0
var multiplayer_panel: VBoxContainer
var player_list_label: Label

var hunger_bar: ProgressBar
var energy_bar: ProgressBar
var fun_bar: ProgressBar
var hygiene_bar: ProgressBar
var social_bar: ProgressBar

var menu_visible: bool = false
var menu_panel: PanelContainer

func _ready() -> void:
	_setup_hud()
	_setup_needs_panel()
	_setup_message_area()
	_setup_multiplayer_panel()
	_setup_menu()

	# Connect to game manager signals (should exist now - created before UI)
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		if not gm.money_changed.is_connected(_on_money_changed):
			gm.money_changed.connect(_on_money_changed)
		if not gm.message_displayed.is_connected(_on_message_displayed):
			gm.message_displayed.connect(_on_message_displayed)
		if not gm.day_started.is_connected(_on_day_started):
			gm.day_started.connect(_on_day_started)

func _process(_delta: float) -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		if time_label:
			time_label.text = "🕐 " + gm.get_time_string()
		if day_label:
			day_label.text = "📅 Day %d" % gm.current_day
		_update_needs_display()

	# Fade message
	if message_label and message_label.visible:
		message_timer -= _delta
		if message_timer <= 0:
			message_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		menu_visible = !menu_visible
		menu_panel.visible = menu_visible

## ---- Setup Functions ----

func _setup_hud() -> void:
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 40
	top_bar.offset_left = 10
	top_bar.offset_right = -10
	top_bar.offset_top = 10
	add_child(top_bar)

	money_label = Label.new()
	money_label.name = "MoneyLabel"
	money_label.text = "💰 5000$"
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	top_bar.add_child(money_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	day_label = Label.new()
	day_label.name = "DayLabel"
	day_label.text = "📅 Day 1"
	day_label.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(day_label)

	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "🕐 08:00"
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.offset_left = 10
	top_bar.add_child(time_label)

func _setup_needs_panel() -> void:
	needs_container = VBoxContainer.new()
	needs_container.name = "NeedsPanel"
	needs_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	needs_container.offset_left = 10
	needs_container.offset_top = 60
	needs_container.offset_right = 200
	needs_container.offset_bottom = 260
	add_child(needs_container)

	var needs_data := [
		["🍖 Hunger", "hunger", Color(1, 0.4, 0.2)],
		["⚡ Energy", "energy", Color(0.2, 0.6, 1)],
		["🎮 Fun", "fun", Color(1, 0.8, 0.2)],
		["🚿 Hygiene", "hygiene", Color(0.3, 0.8, 0.9)],
		["💬 Social", "social", Color(0.9, 0.4, 0.8)]
	]

	for nd in needs_data:
		var hbox := HBoxContainer.new()
		needs_container.add_child(hbox)

		var lbl := Label.new()
		lbl.text = nd[0]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.custom_minimum_size.x = 90
		hbox.add_child(lbl)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(90, 16)
		bar.max_value = 100
		bar.value = 100
		bar.show_percentage = false
		var style := StyleBoxFlat.new()
		style.bg_color = nd[2]
		corner_radius_all(style, 4)
		bar.add_theme_stylebox_override("fill", style)
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		corner_radius_all(bg_style, 4)
		bar.add_theme_stylebox_override("background", bg_style)
		hbox.add_child(bar)

		match nd[1]:
			"hunger": hunger_bar = bar
			"energy": energy_bar = bar
			"fun": fun_bar = bar
			"hygiene": hygiene_bar = bar
			"social": social_bar = bar

func _setup_message_area() -> void:
	# Background panel for message
	var msg_bg := PanelContainer.new()
	msg_bg.name = "MessageBG"
	msg_bg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	msg_bg.offset_bottom = -75
	msg_bg.offset_top = -125
	msg_bg.offset_left = 180
	msg_bg.offset_right = -180
	var msg_style := StyleBoxFlat.new()
	msg_style.bg_color = Color(0, 0, 0, 0.6)
	corner_radius_all(msg_style, 8)
	msg_bg.add_theme_stylebox_override("panel", msg_style)
	add_child(msg_bg)

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_bottom = -80
	message_label.offset_top = -120
	message_label.offset_left = 200
	message_label.offset_right = -200
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	message_label.visible = false
	add_child(message_label)

func _setup_multiplayer_panel() -> void:
	multiplayer_panel = VBoxContainer.new()
	multiplayer_panel.name = "MultiplayerPanel"
	multiplayer_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	multiplayer_panel.offset_right = -10
	multiplayer_panel.offset_top = 50
	multiplayer_panel.offset_left = -180
	multiplayer_panel.offset_bottom = 200
	add_child(multiplayer_panel)

	var title := Label.new()
	title.text = "🌐 Online"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	multiplayer_panel.add_child(title)

	player_list_label = Label.new()
	player_list_label.text = "1 player"
	player_list_label.add_theme_font_size_override("font_size", 14)
	player_list_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	multiplayer_panel.add_child(player_list_label)

func _setup_menu() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.offset_left = -200
	menu_panel.offset_right = 200
	menu_panel.offset_top = -200
	menu_panel.offset_bottom = 200
	menu_panel.visible = false
	add_child(menu_panel)

	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	corner_radius_all(menu_style, 12)
	menu_panel.add_theme_stylebox_override("panel", menu_style)

	var vbox := VBoxContainer.new()
	menu_panel.add_child(vbox)

	var title := Label.new()
	title.text = "📋 Menu"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var buttons := ["Resume", "Settings", "Disconnect", "Quit"]
	for btn_text in buttons:
		var btn := Button.new()
		btn.text = btn_text
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size = Vector2(200, 40)
		btn.pressed.connect(_on_menu_button.bind(btn_text))
		vbox.add_child(btn)

## ---- Update Functions ----

func update_player_info(p_name: String, new_money: int, house_count: int) -> void:
	if money_label:
		money_label.text = "💰 %d$" % new_money

func update_player_list(players: Array) -> void:
	if not player_list_label:
		return
	var count := players.size()
	player_list_label.text = "%d player%s" % [count, "s" if count != 1 else ""]
	for i in range(count):
		player_list_label.text += "\n  • %s" % players[i]

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
		message_timer = 4.0

func _on_money_changed(new_amount: int) -> void:
	if money_label:
		money_label.text = "💰 %d$" % new_amount

func _on_message_displayed(text: String) -> void:
	show_message(text)

func _on_day_started(day: int) -> void:
	show_message("Day %d has begun!" % day)

func _update_needs_display() -> void:
	var gm = get_node_or_null("/root/Main/GameManager")
	if not gm:
		return
	if hunger_bar: hunger_bar.value = gm.get_need("hunger")
	if energy_bar: energy_bar.value = gm.get_need("energy")
	if fun_bar: fun_bar.value = gm.get_need("fun")
	if hygiene_bar: hygiene_bar.value = gm.get_need("hygiene")
	if social_bar: social_bar.value = gm.get_need("social")

func _on_menu_button(button_text: String) -> void:
	match button_text:
		"Resume":
			menu_visible = false
			menu_panel.visible = false
		"Disconnect":
			var mp = get_node_or_null("/root/Main/MultiplayerController")
			if mp and mp.has_method("disconnect_from_game"):
				mp.disconnect_from_game()
			menu_visible = false
			menu_panel.visible = false
		"Quit":
			get_tree().quit()

func corner_radius_all(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
