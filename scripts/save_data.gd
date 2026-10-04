class_name SaveData
extends RefCounted
## One readable local JSON file. Invalid files never replace player progress.

const VERSION: int = 1
const MAX_SAVED_NUMBER: int = 2000000000


static func read(path: String) -> Dictionary:
	var primary := _read_file(path)
	if primary["ok"]:
		return primary
	# A previous valid JSON file can recover a missing or damaged main save.
	var backup := _read_file(path + ".bak")
	return backup if backup["ok"] else primary


static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("No saved progress yet.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("Could not open saved progress.")
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Dictionary:
		return _failure("Saved progress is not a valid JSON object.")
	var data: Dictionary = json.data
	if not _whole_number(data.get("version"), 1) or int(data["version"]) != VERSION:
		return _failure("Unsupported save version.")
	for key in ["coins", "xp", "gems", "level"]:
		if not _whole_number(data.get(key), 1 if key == "level" else 0):
			return _failure("Invalid saved %s." % key)
		data[key] = int(data[key])
	if not data.get("completed_jobs") is Array:
		return _failure("Invalid completed job list.")
	var completed: Array[String] = []
	for job_id in data["completed_jobs"]:
		if not job_id is String or JobsCatalog.find_job(job_id) == null or completed.has(job_id):
			return _failure("Invalid or repeated completed job.")
		completed.append(job_id)
	data["completed_jobs"] = completed
	return {"ok": true, "data": data, "error": ""}


static func write(path: String, data: Dictionary) -> Error:
	# Write first. Keep a backup because file replacement can fail on Windows.
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	var primary_path := ProjectSettings.globalize_path(path)
	var backup_path := primary_path + ".bak"
	# Never replace a good backup with a damaged primary.
	if _read_file(path)["ok"]:
		var backup_error := DirAccess.copy_absolute(primary_path, backup_path)
		if backup_error != OK:
			return backup_error
	var replace_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path), primary_path
	)
	if replace_error != OK and _read_file(path + ".bak")["ok"]:
		# If Windows removed the old target first, recover its previous contents.
		# The backup remains available even if a file lock prevents this copy.
		DirAccess.copy_absolute(backup_path, primary_path)
	return replace_error


static func _whole_number(value: Variant, minimum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= MAX_SAVED_NUMBER


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "data": {}, "error": message}
