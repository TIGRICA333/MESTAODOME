extends Node

## Auto Updater - checks GitHub for new releases

signal update_available(current_version: String, new_version: String, download_url: String)
signal update_check_failed(error: String)
signal download_progress(progress: float)
signal download_completed()

const GITHUB_OWNER: String = "TIGRICA333"
const GITHUB_REPO: String = "MESTAODOME"
const GITHUB_API_URL: String = "https://api.github.com/repos/%s/%s/releases/latest"

const GAME_VERSION: String = "1.2.0"

var latest_version: String = ""
var download_url: String = ""
var is_checking: bool = false
var http_request: HTTPRequest
var download_request: HTTPRequest
var check_delay: float = 3.0

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.name = "UpdateChecker"
	http_request.timeout = 10.0
	add_child(http_request)
	http_request.request_completed.connect(_on_check_completed)

	download_request = HTTPRequest.new()
	download_request.name = "Downloader"
	download_request.timeout = 120.0
	add_child(download_request)
	download_request.request_completed.connect(_on_download_completed)

	# Delay check to avoid blocking startup
	await get_tree().create_timer(check_delay).timeout
	check_for_updates()

func check_for_updates() -> void:
	if is_checking:
		return

	is_checking = true
	var url: String = GITHUB_API_URL % [GITHUB_OWNER, GITHUB_REPO]
	print("[Updater] Checking: ", url)

	var error := http_request.request(url, ["Accept: application/vnd.github.v3+json"])
	if error != OK:
		is_checking = false
		print("[Updater] Request failed: ", error_string(error))

func _on_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_checking = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[Updater] Check failed (result=", result, " code=", response_code, ")")
		return

	var json_text: String = body.get_string_from_utf8()
	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		print("[Updater] JSON parse error")
		return

	var data: Dictionary = json.data
	latest_version = data.get("tag_name", "").trim_prefix("v")

	if latest_version == "":
		print("[Updater] No version in response")
		return

	print("[Updater] Current: %s | Latest: %s" % [GAME_VERSION, latest_version])

	if _version_is_newer(latest_version, GAME_VERSION):
		print("[Updater] New version available!")
		download_url = _find_exe_url(data)
		if download_url != "":
			update_available.emit(GAME_VERSION, latest_version, download_url)
		else:
			print("[Updater] No .exe found")
	else:
		print("[Updater] Game is up to date!")

func start_download() -> void:
	if download_url == "":
		print("[Updater] No download URL")
		return

	print("[Updater] Downloading: ", download_url)
	var error := download_request.request(download_url)
	if error != OK:
		print("[Updater] Download request failed: ", error_string(error))

func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[Updater] Download failed")
		return

	print("[Updater] Download complete! Size: ", body.size(), " bytes")

	# Save the downloaded file
	var exe_path := OS.get_executable_path().get_base_dir()
	var new_exe_path := exe_path.path_join("BuildYourHouse_new.exe")

	var file := FileAccess.open(new_exe_path, FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		file.close()
		print("[Updater] Saved to: ", new_exe_path)

		# Create batch file to replace the old exe
		_create_update_batch(exe_path, new_exe_path)
		download_completed.emit()

		# Quit and let batch file handle replacement
		get_tree().quit()
	else:
		print("[Updater] Failed to save file")

func _create_update_batch(exe_dir: String, new_path: String) -> void:
	var bat_path := exe_dir.path_join("update.bat")
	var exe_name := OS.get_executable_path().get_file()
	var old_path := exe_dir.path_join(exe_name)

	var bat_content := """@echo off
timeout /t 2 /nobreak >nul
del "%s"
ren "%s" "%s"
start "" "%s"
del "%%~f0"
""" % [old_path, new_path, exe_name, old_path]

	var file := FileAccess.open(bat_path, FileAccess.WRITE)
	if file:
		file.store_string(bat_content)
		file.close()

		# Execute the batch file
		OS.shell_open(bat_path)

func _version_is_newer(new_ver: String, current_ver: String) -> bool:
	var new_parts := new_ver.split(".")
	var cur_parts := current_ver.split(".")
	for i in range(min(new_parts.size(), cur_parts.size())):
		var n := int(new_parts[i]) if new_parts[i].is_valid_int() else 0
		var c := int(cur_parts[i]) if cur_parts[i].is_valid_int() else 0
		if n > c:
			return true
		elif n < c:
			return false
	return new_parts.size() > cur_parts.size()

func _find_exe_url(release_data: Dictionary) -> String:
	for asset in release_data.get("assets", []):
		var name: String = asset.get("name", "")
		if name.ends_with(".exe") or name.ends_with(".zip"):
			return asset.get("browser_download_url", "")
	return ""

func get_version() -> String:
	return GAME_VERSION
