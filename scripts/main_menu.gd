extends Control

## Main Menu - entry point, shows before game starts

var name_input: LineEdit
var ip_input: LineEdit
var port_input: LineEdit
var status_label: Label

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.12, 0.18, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main container
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_vbox.offset_left = -200
	main_vbox.offset_right = 200
	main_vbox.offset_top = -250
	main_vbox.offset_bottom = 250
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "🏠 Build Your House"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	main_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Строй • Живи • Общайся"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	main_vbox.add_child(subtitle)

	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Player name
	var name_label := Label.new()
	name_label.text = "Your Name:"
	name_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(name_label)

	name_input = LineEdit.new()
	name_input.placeholder_text = "Enter your name..."
	name_input.text = "Player"
	name_input.custom_minimum_size = Vector2(300, 35)
	main_vbox.add_child(name_input)

	# Server IP
	var ip_label := Label.new()
	ip_label.text = "Server IP:"
	ip_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(ip_label)

	ip_input = LineEdit.new()
	ip_input.placeholder_text = "127.0.0.1"
	ip_input.text = "127.0.0.1"
	ip_input.custom_minimum_size = Vector2(300, 35)
	main_vbox.add_child(ip_input)

	# Port
	var port_label := Label.new()
	port_label.text = "Port:"
	port_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(port_label)

	port_input = LineEdit.new()
	port_input.placeholder_text = "7777"
	port_input.text = "7777"
	port_input.custom_minimum_size = Vector2(300, 35)
	main_vbox.add_child(port_input)

	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(btn_container)

	# Host button
	var host_btn := Button.new()
	host_btn.text = "🖥️ Host Game"
	host_btn.custom_minimum_size = Vector2(140, 45)
	host_btn.add_theme_font_size_override("font_size", 18)
	host_btn.pressed.connect(_on_host_pressed)
	btn_container.add_child(host_btn)

	# Join button
	var join_btn := Button.new()
	join_btn.text = "🔌 Join Game"
	join_btn.custom_minimum_size = Vector2(140, 45)
	join_btn.add_theme_font_size_override("font_size", 18)
	join_btn.pressed.connect(_on_join_pressed)
	btn_container.add_child(join_btn)

	# Solo button
	var solo_btn := Button.new()
	solo_btn.text = "🎮 Solo Play"
	solo_btn.custom_minimum_size = Vector2(300, 45)
	solo_btn.add_theme_font_size_override("font_size", 18)
	solo_btn.pressed.connect(_on_solo_pressed)
	main_vbox.add_child(solo_btn)

	# Status
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	main_vbox.add_child(status_label)

	# Credits
	var credits := Label.new()
	credits.text = "Made with Godot 4 ❤️"
	credits.add_theme_font_size_override("font_size", 12)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	main_vbox.add_child(credits)

func _on_host_pressed() -> void:
	status_label.text = "Starting server..."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))

	# Store connection info for main scene to use
	var port := int(port_input.text) if port_input.text.is_valid_int() else 7777
	_save_connection_data("host", "", port)

	_start_game()

func _on_join_pressed() -> void:
	status_label.text = "Connecting..."
	status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))

	var ip := ip_input.text if ip_input.text != "" else "127.0.0.1"
	var port := int(port_input.text) if port_input.text.is_valid_int() else 7777
	_save_connection_data("join", ip, port)

	_start_game()

func _on_solo_pressed() -> void:
	_save_connection_data("solo", "", 0)
	_start_game()

func _save_connection_data(mode: String, ip: String, port: int) -> void:
	# Store in root so main.gd can read it
	var root := get_tree().root
	root.set_meta("mp_mode", mode)
	root.set_meta("mp_ip", ip)
	root.set_meta("mp_port", port)
	root.set_meta("player_name", name_input.text if name_input else "Player")

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
