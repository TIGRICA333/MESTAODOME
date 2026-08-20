extends Node

## Auto Updater - checks GitHub for new releases
## Shows update dialog with Yes/No/Later options
## Downloads and installs update automatically

signal update_available(current_version: String, new_version: String, download_url: String)
signal update_check_failed(error: String)
signal update_progress(progress: float)
signal update_downloaded(save_path: String)

# ⚠️ CONFIGURE THIS — your GitHub repo
const GITHUB_OWNER: String = "TIGRICA333"
const GITHUB_REPO: String = "MESTAODOME"
const GITHUB_API_URL: String = "https://api.github.com/repos/%s/%s/releases/latest"
const GITHUB_DOWNLOAD_URL: String = "https://github.com/%s/%s/releases/download/%s/SimsWorld.exe"

# Current game version
const GAME_VERSION: String = "1.0.0"

# Update state
var latest_version: String = ""
var download_url: String = ""
var is_checking: bool = false
var http_request: HTTPRequest
var download_request: HTTPRequest

func _ready() -> void:
	# Create HTTP request nodes
	http_request = HTTPRequest.new()
	http_request.name = "UpdateChecker"
	http_request.timeout = 10.0
	add_child(http_request)
	http_request.request_completed.connect(_on_check_completed)

	download_request = HTTPRequest.new()
	download_request.name = "UpdateDownloader"
	add_child(download_request)
	download_request.request_completed.connect(_on_download_completed)

	# Check for updates on startup (delay 2 seconds)
	await get_tree().create_timer(2.0).timeout
	check_for_updates()

func check_for_updates() -> void:
	if is_checking:
		return

	is_checking = true
	var url: String = GITHUB_API_URL % [GITHUB_OWNER, GITHUB_REPO]
	print("[Updater] Checking for updates at: ", url)

	var error := http_request.request(url, ["Accept: application/vnd.github.v3+json"])
	if error != OK:
		is_checking = false
		update_check_failed.emit("Failed to connect to update server")
		print("[Updater] Request failed: ", error_string(error))

func _on_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_checking = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[Updater] Connection failed (result: ", result, ")")
		update_check_failed.emit("Connection failed")
		return

	if response_code != 200:
		print("[Updater] Server returned code: ", response_code)
		update_check_failed.emit("Server error: %d" % response_code)
		return

	var json_text: String = body.get_string_from_utf8()
	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		print("[Updater] Failed to parse response")
		update_check_failed.emit("Invalid response")
		return

	var data: Dictionary = json.data
	latest_version = data.get("tag_name", "").trim_prefix("v")

	if latest_version == "":
		print("[Updater] No version found in response")
		update_check_failed.emit("No version found")
		return

	print("[Updater] Current: %s | Latest: %s" % [GAME_VERSION, latest_version])

	if _version_is_newer(latest_version, GAME_VERSION):
		print("[Updater] 🆕 New version available!")
		# Find .exe download URL
		download_url = _find_exe_url(data)
		if download_url != "":
			update_available.emit(GAME_VERSION, latest_version, download_url)
		else:
			print("[Updater] No .exe found in release")
			update_check_failed.emit("No .exe download found")
	else:
		print("[Updater] ✅ Game is up to date!")

func _version_is_newer(new_ver: String, current_ver: String) -> bool:
	var new_parts := new_ver.split(".")
	var cur_parts := current_ver.split(".")

	for i in range(min(new_parts.size(), cur_parts.size())):
		var new_num := int(new_parts[i]) if new_parts[i].is_valid_int() else 0
		var cur_num := int(cur_parts[i]) if cur_parts[i].is_valid_int() else 0
		if new_num > cur_num:
			return true
		elif new_num < cur_num:
			return false

	return new_parts.size() > cur_parts.size()

func _find_exe_url(release_data: Dictionary) -> String:
	var assets: Array = release_data.get("assets", [])
	for asset in assets:
		var name: String = asset.get("name", "")
		if name.ends_with(".exe") or name.ends_with(".zip"):
			return asset.get("browser_download_url", "")
	return ""

func start_download() -> void:
	if download_url == "":
		print("[Updater] No download URL available")
		return

	print("[Updater] Starting download: ", download_url)
	var error := download_request.request(download_url)
	if error != OK:
		print("[Updater] Download request failed: ", error_string(error))

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[Updater] Download failed (result: ", result, ")")
		return

	if response_code != 200:
		print("[Updater] Download failed (code: ", response_code, ")")
		return

	# Save to temp location
	var exe_path := OS.get_executable_path()
	var exe_dir := exe_path.get_base_dir()
	var save_path := exe_dir.path_join("SimsWorld_new.exe")

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("[Updater] Failed to save update: ", save_path)
		return

	file.store_buffer(body)
	file.close()

	print("[Updater] ✅ Update downloaded to: ", save_path)
	update_downloaded.emit(save_path)

	# Run the batch file to replace and restart
	_apply_update(save_path)

func _apply_update(new_exe_path: String) -> void:
	var exe_path := OS.get_executable_path()
	var bat_path := exe_path.get_base_dir().path_join("update.bat")

	# Create the batch file that will replace the exe and restart
	var bat_content := """@echo off
echo Updating SimsWorld...
timeout /t 2 /nobreak > nul
taskkill /f /im SimsWorld.exe > nul 2>&1
timeout /t 1 /nobreak > nul
copy /y "%s" "%s"
del "%s"
echo Update complete! Starting game...
start "" "%s"
del "%%~f0"
""" % [new_exe_path, exe_path, new_exe_path, exe_path]

	var bat_file := FileAccess.open(bat_path, FileAccess.WRITE)
	if bat_file:
		bat_file.store_string(bat_content)
		bat_file.close()

	# Execute the batch file
	OS.create_process(bat_path, [])
	print("[Updater] Update applied! Restarting...")

	# Quit current game
	get_tree().quit()

func get_version() -> String:
	return GAME_VERSION

func get_full_version_text() -> String:
	return "v%s" % GAME_VERSION
