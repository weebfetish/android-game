extends Node
## Player progression is saved locally. Customer budgets do not spend rewards.

signal state_changed

var customer_name: String = "Mika"
var customer_request: String = "I need a basic study PC for homework, web browsing, and documents."
var customer_budget: int = 60000
var reward_coins: int = 5000
var reward_xp: int = 100
var reward_gems: int = 1
var coins: int = 0
var xp: int = 0
var level: int = 1
var gems: int = 50
var completed_jobs: PackedStringArray = []
var current_job_id: String = "study"
var active_job: JobData
var selected_parts: Dictionary = {}
var last_result: Dictionary = {}
var reward_claimed: bool = false
var last_reward_gems: int = 0

var save_path: String = "user://pc_builder_save.json"
var save_enabled: bool = true
var save_error: String = ""

# Reward checks retain both the evaluated build and the exact job terms.
var _evaluated_selection: Dictionary = {}
var _evaluated_job: Dictionary = {}
var _evaluated_budget: int = 0


func _ready() -> void:
	_apply_job(JobsCatalog.find_job("study"))
	# Automated checks use their own files, never a player's actual save.
	for argument in OS.get_cmdline_args():
		if argument.replace("\\", "/").contains("/tests/"):
			save_enabled = false
	if save_enabled and (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")):
		load_progress()


static func level_for_xp(total_xp: int) -> int:
	# Level n starts at 50 * n * (n - 1) XP: 0, 100, 300, 600, 1000...
	var result: int = 1
	while total_xp >= 50 * result * (result + 1):
		result += 1
	return result


func get_current_job() -> JobData:
	if active_job == null:
		_apply_job(JobsCatalog.find_job(current_job_id))
	return active_job


func available_jobs() -> Array[JobData]:
	var available: Array[JobData] = []
	for job in JobsCatalog.get_jobs():
		if job.unlock_level <= level:
			available.append(job)
	return available


func is_job_unlocked(job_id: String) -> bool:
	var job := JobsCatalog.find_job(job_id)
	return job != null and job.unlock_level <= level


func next_job() -> JobData:
	for job in available_jobs():
		if not completed_jobs.has(job.id):
			return job
	return null


func start_next_job() -> bool:
	var job := next_job()
	return start_job(job.id if job != null else current_job_id)


func start_job(job_id: String) -> bool:
	if not is_job_unlocked(job_id):
		return false
	_apply_job(JobsCatalog.find_job(job_id))
	start_new_request()
	return true


func _apply_job(job: JobData) -> void:
	active_job = job
	current_job_id = job.id
	customer_name = job.name
	customer_request = job.request
	customer_budget = job.budget
	reward_coins = job.reward_coins
	reward_xp = job.reward_xp
	reward_gems = job.reward_gems


func requirement_text() -> String:
	var job := get_current_job()
	var text := "CPU score %d+ · RAM %d GB+ · SSD %d GB+" % [
		job.min_cpu_score, job.min_ram_gb, job.min_ssd_gb,
	]
	if not job.storage_interface.is_empty():
		text += " · %s storage" % job.storage_interface
	return text


func start_new_request() -> void:
	selected_parts.clear()
	last_result.clear()
	_evaluated_selection.clear()
	_evaluated_job.clear()
	reward_claimed = false
	last_reward_gems = 0
	state_changed.emit()


func can_select_part(part: PartData) -> bool:
	if part == null or part.unlock_level > level:
		return false
	# A copied Resource cannot lower the catalog's level requirement.
	var original := PartsCatalog.find_part(part.id)
	return original != null and original.unlock_level <= level


func select_part(category: String, part: PartData) -> void:
	if not PartsCatalog.CATEGORIES.has(category):
		return
	if part != null and (part.category != category or not can_select_part(part)):
		return
	# Passing null clears a slot. Clearing an empty slot changes nothing.
	if part == null:
		if not selected_parts.erase(category):
			return
	else:
		selected_parts[category] = part
	last_result.clear()
	_evaluated_selection.clear()
	_evaluated_job.clear()
	state_changed.emit()


func total_cost() -> int:
	return BuildValidator.total_cost(selected_parts)


func has_all_parts() -> bool:
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = selected_parts.get(category)
		if not candidate is PartData or candidate.category != category:
			return false
	return true


func _validate_current_build() -> Dictionary:
	var result := BuildValidator.validate(selected_parts, customer_budget, get_current_job().requirements())
	var lock_reasons: PackedStringArray = []
	if not is_job_unlocked(current_job_id):
		lock_reasons.append("This job is not unlocked at your current level.")
	for category in PartsCatalog.CATEGORIES:
		var part: Variant = selected_parts.get(category)
		if part is PartData and not can_select_part(part):
			lock_reasons.append("%s requires a higher player level." % part.display_name)
	if not lock_reasons.is_empty():
		result["success"] = false
		for reason in lock_reasons:
			result["reasons"].append("Level unlock: " + reason)
			result["checks"].append({"passed": false, "title": "Level unlock", "detail": reason})
	return result


func evaluate_build() -> Dictionary:
	last_result = _validate_current_build()
	_evaluated_selection = _selection_snapshot()
	_evaluated_job = _job_snapshot()
	_evaluated_budget = customer_budget
	state_changed.emit()
	return last_result


func claim_reward() -> bool:
	if reward_claimed or not last_result.get("success", false):
		return false
	if _evaluated_selection != _selection_snapshot() or _evaluated_budget != customer_budget:
		return false
	if _evaluated_job != _job_snapshot() or not _validate_current_build()["success"]:
		return false
	last_reward_gems = 0 if completed_jobs.has(current_job_id) else reward_gems
	coins += reward_coins
	xp += reward_xp
	level = level_for_xp(xp)
	gems += last_reward_gems
	if not completed_jobs.has(current_job_id):
		completed_jobs.append(current_job_id)
	reward_claimed = true
	save_progress()
	state_changed.emit()
	return true


func _job_snapshot() -> Dictionary:
	var job := get_current_job()
	return {
		"id": current_job_id,
		"name": customer_name,
		"request": customer_request,
		"budget": customer_budget,
		"requirements": job.requirements().duplicate(true),
		"unlock_level": job.unlock_level,
		# Also catch edits to the Resource from which this request was started.
		"job_definition": {
			"id": job.id, "budget": job.budget,
			"reward_coins": job.reward_coins,
			"reward_xp": job.reward_xp,
			"reward_gems": job.reward_gems,
		},
		"reward_coins": reward_coins,
		"reward_xp": reward_xp,
		"reward_gems": reward_gems,
	}


func _selection_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = selected_parts.get(category)
		if candidate is PartData:
			snapshot[category] = {
				"id": candidate.id,
				"category": candidate.category,
				"display_name": candidate.display_name,
				"price": candidate.price,
				"socket": candidate.socket,
				"ram_type": candidate.ram_type,
				"power_draw": candidate.power_draw,
				"wattage": candidate.wattage,
				"capacity_gb": candidate.capacity_gb,
				"interface_type": candidate.interface_type,
				"supported_storage_interfaces": candidate.supported_storage_interfaces.duplicate(),
				"cpu_score": candidate.cpu_score,
				"unlock_level": candidate.unlock_level,
			}
	return snapshot


func save_progress() -> bool:
	if not save_enabled:
		return true
	# XP is authoritative if a debug tool has edited it directly.
	level = level_for_xp(xp)
	var error := SaveData.write(save_path, {
		"version": SaveData.VERSION,
		"coins": coins,
		"xp": xp,
		"level": level,
		"gems": gems,
		"completed_jobs": Array(completed_jobs),
	})
	save_error = "" if error == OK else "Could not save progress (error %d)." % error
	return error == OK


func load_progress() -> bool:
	var saved := SaveData.read(save_path)
	if not saved["ok"]:
		save_error = saved["error"] if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak") else ""
		return false
	var data: Dictionary = saved["data"]
	coins = data["coins"]
	xp = data["xp"]
	level = level_for_xp(xp)
	gems = data["gems"]
	completed_jobs = PackedStringArray(data["completed_jobs"])
	save_error = ""
	var job := next_job()
	_apply_job(job if job != null else JobsCatalog.find_job("study"))
	start_new_request()
	return true


func reset_progress() -> void:
	coins = 0
	xp = 0
	level = 1
	gems = 50
	completed_jobs = []
	save_error = ""
	_apply_job(JobsCatalog.find_job("study"))
	start_new_request()
