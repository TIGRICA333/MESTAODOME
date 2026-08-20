extends CanvasLayer

## Update Dialog - shows when new version is available
## Options: Update Now / Skip / Remind Later

var panel: PanelContainer
var title_label: Label
var desc_label: Label
var progress_bar: ProgressBar
var status_label: Label
var btn_container: VBoxContainer

var current_version: String = ""
var new_version: String = ""
var download_url: String = ""
var is_downloading: bool = false

func _ready() -> void:
	visible = false
	_setup_ui()

func _setup_ui() -> void:
	# Semi-transparent background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main panel
	panel = PanelContainer.new()
	panel.name = "UpdatePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -180
	panel.offset_bottom = 180
	add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.15, 0.2, 0.98)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.3, 0.5, 0.9, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Update icon
	var icon_label := Label.new()
	icon_label.text = "🔄"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# Title
	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "Доступно обновление!"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(title_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Description
	desc_label = Label.new()
	desc_label.name = "Description"
	desc_label.text = "Новая версия игры доступна для скачивания."
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 50
	vbox.add_child(desc_label)

	# Version info
	var version_box := HBoxContainer.new()
	version_box.alignment = BoxContainer.ALIGNMENT_CENTER
	version_box.add_theme_constant_override("separation", 15)
	vbox.add_child(version_box)

	var current_label := Label.new()
	current_label.text = "📱 Текущая: v%s" % current_version
	current_label.add_theme_font_size_override("font_size", 14)
	current_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	version_box.add_child(current_label)

	var arrow_label := Label.new()
	arrow_label.text = "→"
	arrow_label.add_theme_font_size_override("font_size", 18)
	arrow_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	version_box.add_child(arrow_label)

	var new_label := Label.new()
	new_label.text = "🆕 Новая: v%s" % new_version
	new_label.add_theme_font_size_override("font_size", 14)
	new_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
	version_box.add_child(new_label)

	# Progress bar (hidden initially)
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(380, 20)
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.visible = false
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.15, 0.15, 0.2, 1)
	progress_bg.corner_radius_top_left = 6
	progress_bg.corner_radius_top_right = 6
	progress_bg.corner_radius_bottom_left = 6
	progress_bg.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("background", progress_bg)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.2, 0.7, 0.3, 1)
	progress_fill.corner_radius_top_left = 6
	progress_fill.corner_radius_top_right = 6
	progress_fill.corner_radius_bottom_left = 6
	progress_fill.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("fill", progress_fill)
	vbox.add_child(progress_bar)

	# Status label
	status_label = Label.new()
	status_label.name = "Status"
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false
	vbox.add_child(status_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Button container
	btn_container = VBoxContainer.new()
	btn_container.name = "Buttons"
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_container)

	# Update Now button
	var update_btn := Button.new()
	update_btn.name = "UpdateBtn"
	update_btn.text = "✅ Обновить сейчас"
	update_btn.custom_minimum_size = Vector2(350, 42)
	update_btn.add_theme_font_size_override("font_size", 18)
	update_btn.pressed.connect(_on_update_pressed)
	var update_style := StyleBoxFlat.new()
	update_style.bg_color = Color(0.15, 0.6, 0.25, 1)
	update_style.corner_radius_top_left = 8
	update_style.corner_radius_top_right = 8
	update_style.corner_radius_bottom_left = 8
	update_style.corner_radius_bottom_right = 8
	update_btn.add_theme_stylebox_override("normal", update_style)
	var update_hover := update_style.duplicate()
	update_hover.bg_color = Color(0.2, 0.7, 0.3, 1)
	update_btn.add_theme_stylebox_override("hover", update_hover)
	btn_container.add_child(update_btn)

	# Remind Later button
	var remind_btn := Button.new()
	remind_btn.name = "RemindBtn"
	remind_btn.text = "⏰ Напомнить позже"
	remind_btn.custom_minimum_size = Vector2(350, 38)
	remind_btn.add_theme_font_size_override("font_size", 16)
	remind_btn.pressed.connect(_on_remind_pressed)
	var remind_style := StyleBoxFlat.new()
	remind_style.bg_color = Color(0.3, 0.3, 0.4, 1)
	remind_style.corner_radius_top_left = 8
	remind_style.corner_radius_top_right = 8
	remind_style.corner_radius_bottom_left = 8
	remind_style.corner_radius_bottom_right = 8
	remind_btn.add_theme_stylebox_override("normal", remind_style)
	var remind_hover := remind_style.duplicate()
	remind_hover.bg_color = Color(0.4, 0.4, 0.5, 1)
	remind_btn.add_theme_stylebox_override("hover", remind_hover)
	btn_container.add_child(remind_btn)

	# Skip button
	var skip_btn := Button.new()
	skip_btn.name = "SkipBtn"
	skip_btn.text = "❌ Пропустить"
	skip_btn.custom_minimum_size = Vector2(350, 38)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(_on_skip_pressed)
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.4, 0.2, 0.2, 1)
	skip_style.corner_radius_top_left = 8
	skip_style.corner_radius_top_right = 8
	skip_style.corner_radius_bottom_left = 8
	skip_style.corner_radius_bottom_right = 8
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	var skip_hover := skip_style.duplicate()
	skip_hover.bg_color = Color(0.5, 0.3, 0.3, 1)
	skip_btn.add_theme_stylebox_override("hover", skip_hover)
	btn_container.add_child(skip_btn)

## ---- Public Methods ----

func show_update_dialog(current: String, new_ver: String, url: String) -> void:
	current_version = current
	new_version = new_ver
	download_url = url

	# Update text
	desc_label.text = "Доступна новая версия SimsWorld!\nОбновление включает исправления и улучшения."
	$"Content/VersionInfo".visible = false  # Will be updated via version_box

	# Update version labels (find them in the tree)
	var version_box = _find_child_recursive(panel, "HBoxContainer")
	if version_box:
		for child in version_box.get_children():
			if child is Label:
				if "Текущая" in child.text:
					child.text = "📱 Текущая: v%s" % current
				elif "Новая" in child.text:
					child.text = "🆕 Новая: v%s" % new_ver

	# Reset state
	progress_bar.visible = false
	status_label.visible = false
	btn_container.visible = true

	visible = true

func _find_child_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var result := _find_child_recursive(child, name)
		if result:
			return result
	return null

## ---- Button Handlers ----

func _on_update_pressed() -> void:
	print("[Updater] User chose: Update Now")

	# Show progress
	btn_container.visible = false
	progress_bar.visible = true
	status_label.visible = true
	status_label.text = "Скачивание обновления..."
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	progress_bar.value = 0

	# Start download
	var updater = get_node_or_null("/root/Main/AutoUpdater")
	if updater:
		# Connect progress signal
		if not updater.update_progress.is_connected(_on_progress):
			updater.update_progress.connect(_on_progress)
		if not updater.update_downloaded.is_connected(_on_downloaded):
			updater.update_downloaded.connect(_on_downloaded)
		updater.start_download()
	else:
		status_label.text = "Ошибка: updater не найден"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _on_progress(progress: float) -> void:
	progress_bar.value = progress
	if progress >= 100:
		status_label.text = "Установка обновления..."
	else:
		status_label.text = "Скачивание: %d%%" % int(progress)

func _on_downloaded(path: String) -> void:
	status_label.text = "✅ Обновление готово! Перезапуск..."
	status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))

func _on_remind_pressed() -> void:
	print("[Updater] User chose: Remind Later")
	visible = false
	# Check again in 10 minutes
	await get_tree().create_timer(600.0).timeout
	var updater = get_node_or_null("/root/Main/AutoUpdater")
	if updater:
		updater.check_for_updates()

func _on_skip_pressed() -> void:
	print("[Updater] User chose: Skip")
	visible = false
