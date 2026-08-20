extends CanvasLayer

## Update Dialog

var panel: PanelContainer
var title_label: Label
var desc_label: Label
var progress_bar: ProgressBar
var status_label: Label
var btn_container: VBoxContainer

var current_version: String = ""
var new_version: String = ""
var download_url: String = ""

func _ready() -> void:
	visible = false
	_setup_ui()

	# Connect to auto_updater
	var updater = get_node_or_null("/root/Main/AutoUpdater")
	if updater:
		if updater.update_available.is_connected(_on_update_available):
			pass  # Already connected
		else:
			updater.update_available.connect(_on_update_available)

func _on_update_available(cur: String, new_ver: String, url: String) -> void:
	show_update_dialog(cur, new_ver, url)

func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Panel
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -180
	panel.offset_bottom = 180
	add_child(panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.12, 0.15, 0.2, 0.98)
	corner_radius_all(ps, 16)
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_color = Color(0.3, 0.5, 0.9, 0.8)
	panel.add_theme_stylebox_override("panel", ps)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "🔄 Доступно обновление!"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(title_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Description
	desc_label = Label.new()
	desc_label.text = "Хотите обновить игру?"
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Version info
	var vb := HBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 15)
	vbox.add_child(vb)

	var lbl1 := Label.new()
	lbl1.text = "📱 Текущая: v%s" % current_version
	lbl1.add_theme_font_size_override("font_size", 14)
	lbl1.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	vb.add_child(lbl1)

	var arrow := Label.new()
	arrow.text = " → "
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	vb.add_child(arrow)

	var lbl2 := Label.new()
	lbl2.text = "🆕 Новая: v%s" % new_version
	lbl2.add_theme_font_size_override("font_size", 14)
	lbl2.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	vb.add_child(lbl2)

	# Progress bar (hidden)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(380, 20)
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.visible = false
	vbox.add_child(progress_bar)

	# Status
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false
	vbox.add_child(status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buttons
	btn_container = VBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_container)

	var update_btn := Button.new()
	update_btn.text = "✅ Обновить сейчас"
	update_btn.custom_minimum_size = Vector2(350, 42)
	update_btn.add_theme_font_size_override("font_size", 18)
	update_btn.pressed.connect(_on_update_pressed)
	btn_container.add_child(update_btn)

	var remind_btn := Button.new()
	remind_btn.text = "⏰ Напомнить позже"
	remind_btn.custom_minimum_size = Vector2(350, 38)
	remind_btn.add_theme_font_size_override("font_size", 16)
	remind_btn.pressed.connect(_on_remind_pressed)
	btn_container.add_child(remind_btn)

	var skip_btn := Button.new()
	skip_btn.text = "❌ Пропустить"
	skip_btn.custom_minimum_size = Vector2(350, 38)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(_on_skip_pressed)
	btn_container.add_child(skip_btn)

func show_update_dialog(current: String, new_ver: String, url: String) -> void:
	current_version = current
	new_version = new_ver
	download_url = url
	progress_bar.visible = false
	status_label.visible = false
	btn_container.visible = true
	visible = true

func _on_update_pressed() -> void:
	btn_container.visible = false
	progress_bar.visible = true
	status_label.visible = true
	status_label.text = "Скачивание..."
	progress_bar.value = 50

	var updater = get_node_or_null("/root/Main/AutoUpdater")
	if updater:
		updater.download_url = download_url
		updater.start_download()

func _on_remind_pressed() -> void:
	visible = false

func _on_skip_pressed() -> void:
	visible = false

func corner_radius_all(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
