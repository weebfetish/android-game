extends RefCounted
## Progression and local-save checks, called by run_tests.gd with an isolated path.

const JOB_IDS: Array[String] = ["study", "gaming", "esports", "creator", "workstation"]
const BUILD_IDS: Dictionary = {
	"study": ["cpu_s4", "board_a", "ram_ddr4", "ssd_256", "psu_180"],
	"gaming": ["cpu_p6", "board_b", "ram_ddr5", "ssd_512", "psu_350"],
	"esports": ["cpu_g8", "board_b", "ram_ddr5", "ssd_512", "psu_350"],
	"creator": ["cpu_c12", "board_b_plus", "ram_ddr5_32", "ssd_nvme_1024", "psu_550"],
	"workstation": ["cpu_w16", "board_b_pro", "ram_ddr5_64", "ssd_nvme_2048", "psu_750"],
}
const BUILD_COSTS: Array[int] = [38000, 63000, 75000, 115000, 175000]
const BUILD_POWER: Array[int] = [139, 208, 233, 274, 353]

var _tree: SceneTree
var _state: Node
var _report: Callable


func run(tree: SceneTree, state: Node, report: Callable) -> void:
	_tree = tree
	_state = state
	_report = report
	_state.save_enabled = false
	_test_levels_and_locks()
	_test_customer_requirements()
	_test_progression_rewards()
	_test_stale_rewards()
	_test_save_data()
	_state.save_enabled = false
	await _test_five_job_buttons()


func _test_levels_and_locks() -> void:
	_state.reset_progress()
	_expect(_state.coins == 0 and _state.xp == 0 and _state.level == 1 and _state.gems == 50,
		"A new profile starts at level 1 with 50 free gems")
	_expect(_state.completed_jobs.is_empty(), "A new profile has no completed customers")
	_expect(JobsCatalog.get_jobs().size() == 5 and _state.available_jobs().size() == 1,
		"The five-customer catalog initially unlocks only the study job")
	_expect(_state.is_job_unlocked("study") and not _state.is_job_unlocked("gaming"),
		"The study job is available before the gaming job")
	_expect(not _state.start_job("gaming") and _state.current_job_id == "study",
		"Starting a locked customer leaves the current customer unchanged")
	_expect(not _state.start_job("unknown") and _state.current_job_id == "study",
		"An unknown customer cannot become the current job")
	_state.select_part("cpu", PartsCatalog.find_part("cpu_g8"))
	_expect(not _state.selected_parts.has("cpu"), "A locked CPU cannot be selected at level 1")
	var disguised: PartData = PartsCatalog.find_part("cpu_w16")
	disguised.unlock_level = 1
	_state.select_part("cpu", disguised)
	_expect(not _state.selected_parts.has("cpu"), "Lowering a copied part's unlock field cannot bypass its catalog level")
	disguised.id = "unknown_cpu"
	_state.select_part("cpu", disguised)
	_expect(not _state.selected_parts.has("cpu"), "Renaming a locked part to an unknown ID cannot bypass level locks")
	_state.select_part("cpu", PartData.new("custom_cpu", "cpu"))
	_expect(not _state.selected_parts.has("cpu"), "Unknown parts cannot enter a normal player selection")
	for category in PartsCatalog.CATEGORIES:
		_expect(PartsCatalog.get_unlocked_parts(category, 1).size() == 2,
			"Both original %s options are available at level 1" % category)
	var xp_values: Array[int] = [0, 99, 100, 299, 300, 599, 600, 999, 1000, 1499, 1500, 2100]
	var expected_levels: Array[int] = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7]
	for index in range(xp_values.size()):
		_expect(_state.level_for_xp(xp_values[index]) == expected_levels[index],
			"%d XP produces level %d at the exact progression boundary" % [xp_values[index], expected_levels[index]])


func _test_customer_requirements() -> void:
	for index in range(JOB_IDS.size()):
		var job: JobData = JobsCatalog.find_job(JOB_IDS[index])
		var result := BuildValidator.validate(_parts(job.id), job.budget, job.requirements())
		_expect(result["success"] and result["total_cost"] == BUILD_COSTS[index] and result["required_power"] == BUILD_POWER[index],
			"The %s example build meets compatibility, customer requirements, power and budget" % job.id)
		var cpu_short: Dictionary = _parts(job.id)
		cpu_short["cpu"].cpu_score = job.min_cpu_score - 1
		_expect_failure(BuildValidator.validate(cpu_short, job.budget, job.requirements()), "Customer CPU requirement",
			"%s rejects a CPU one score below the minimum" % job.id)
		var ram_short: Dictionary = _parts(job.id)
		ram_short["ram"].capacity_gb = job.min_ram_gb - 1
		_expect_failure(BuildValidator.validate(ram_short, job.budget, job.requirements()), "Customer RAM requirement",
			"%s rejects RAM one GB below the minimum" % job.id)
		var storage_short: Dictionary = _parts(job.id)
		storage_short["ssd"].capacity_gb = job.min_ssd_gb - 1
		_expect_failure(BuildValidator.validate(storage_short, job.budget, job.requirements()), "Customer storage capacity",
			"%s rejects storage one GB below the minimum" % job.id)
		if not job.storage_interface.is_empty():
			var wrong_interface: Dictionary = _parts(job.id)
			wrong_interface["ssd"].interface_type = "SATA"
			_expect_failure(BuildValidator.validate(wrong_interface, job.budget, job.requirements()), "Customer storage interface",
				"%s requires NVMe even when another interface is compatible" % job.id)


func _test_progression_rewards() -> void:
	_state.reset_progress()
	var expected_coins: int = 0
	var expected_xp: int = 0
	for index in range(JOB_IDS.size()):
		var job: JobData = JobsCatalog.find_job(JOB_IDS[index])
		_expect(_state.is_job_unlocked(job.id) and _state.start_job(job.id),
			"Progression unlocks and starts the %s customer" % job.id)
		_select_parts(job.id)
		_expect(_state.evaluate_build()["success"], "The %s customer accepts the complete example build" % job.id)
		expected_coins += job.reward_coins
		expected_xp += job.reward_xp
		_expect(_state.claim_reward(), "The %s customer's successful attempt pays once" % job.id)
		_expect(_state.coins == expected_coins and _state.xp == expected_xp and _state.level == index + 2,
			"The %s reward updates coins, XP and the next level" % job.id)
		_expect(_state.gems == 51 + index and _state.completed_jobs.has(job.id),
			"The first %s completion earns one gem and records the customer" % job.id)
		var after_payment := _progress_snapshot()
		_expect(not _state.claim_reward() and _progress_snapshot() == after_payment,
			"The same %s attempt cannot pay twice" % job.id)
		if index + 1 < JOB_IDS.size():
			var next: JobData = _state.next_job()
			_expect(next != null and next.id == JOB_IDS[index + 1], "The next customer follows the five-job order")
	_expect(_state.coins == 69000 and _state.xp == 1500 and _state.level == 6 and _state.gems == 55,
		"Completing all five customers totals 69,000 coins, 1,500 XP and 55 gems")
	_expect(_state.completed_jobs.size() == 5 and _state.available_jobs().size() == 5,
		"All five customers stay available after completion")
	_state.start_job("study")
	_select_parts("study")
	_state.evaluate_build()
	_expect(_state.claim_reward() and _state.coins == 74000 and _state.xp == 1600 and _state.gems == 55,
		"Replaying a completed customer pays coins and XP without another first-completion gem")


func _test_stale_rewards() -> void:
	for field in ["requirements", "reward_coins", "reward_xp", "reward_gems", "job_unlock", "cpu_score", "part_unlock"]:
		_state.reset_progress()
		# Unlock metadata can change without making this basic build insufficient.
		_state.xp = 1500
		_state.level = 6
		_state.start_job("study")
		_select_parts("study")
		_state.evaluate_build()
		var job: JobData = _state.get_current_job()
		match field:
			"requirements":
				job.min_ram_gb = 7
			"reward_coins":
				job.reward_coins += 1
			"reward_xp":
				job.reward_xp += 1
			"reward_gems":
				job.reward_gems += 1
			"job_unlock":
				job.unlock_level = 2
			"cpu_score":
				_state.selected_parts["cpu"].cpu_score += 1
			"part_unlock":
				_state.selected_parts["cpu"].unlock_level = 2
		var before := _progress_snapshot()
		_expect(not _state.claim_reward() and _progress_snapshot() == before,
			"Changing %s after evaluation rejects a stale reward without changing progress" % field)
	_state.reset_progress()
	_state.start_job("study")
	_select_parts("study")
	_state.evaluate_build()
	_state.start_new_request()
	_expect(not _state.claim_reward(), "Restarting an attempt removes any previous payable result")


func _test_save_data() -> void:
	# The runner supplies a unique test path and disables the normal save file.
	var test_path: String = _state.save_path
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	if FileAccess.file_exists(test_path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".bak"))
	var missing: Dictionary = SaveData.read(test_path)
	_expect(not missing["ok"] and missing["data"].is_empty(), "A missing local save returns no loaded profile")
	var before_missing := _progress_snapshot()
	_expect(not _state.load_progress() and _progress_snapshot() == before_missing,
		"Loading a missing save leaves the current progress unchanged")
	_state.reset_progress()
	_state.save_enabled = true
	for job_id in ["study", "gaming"]:
		_state.start_job(job_id)
		_select_parts(job_id)
		_state.evaluate_build()
		var paid: bool = _state.claim_reward()
		var autosave: Dictionary = SaveData.read(test_path)
		_expect(paid and autosave["ok"] and autosave["data"]["coins"] == _state.coins and autosave["data"]["xp"] == _state.xp and autosave["data"]["gems"] == _state.gems and autosave["data"]["completed_jobs"].has(job_id),
			"Collecting the %s reward automatically saves its new progression" % job_id)
	_state.save_enabled = false
	_state.reset_progress()
	_state.save_enabled = true
	_expect(_state.load_progress() and _state.coins == 13000 and _state.xp == 300 and _state.level == 3 and _state.gems == 52 and _state.completed_jobs == PackedStringArray(["study", "gaming"]) and _state.current_job_id == "esports" and _state.selected_parts.is_empty() and _state.last_result.is_empty(),
		"Resuming the two completed jobs restores progress and offers a fresh esports request")
	_state.save_enabled = false
	_state.reset_progress()
	_state.xp = 1500
	_state.level = 6
	_state.coins = 69000
	_state.gems = 55
	_state.completed_jobs = PackedStringArray(JOB_IDS)
	_state.save_enabled = true
	_expect(_state.save_progress(), "Progress writes to the isolated local JSON save")
	_state.coins += 123
	_expect(_state.save_progress() and SaveData.read(test_path)["data"].get("coins") == 69123 and not FileAccess.file_exists(test_path + ".tmp"),
		"Saving again replaces the profile and removes the temporary file")
	_state.coins = 69000
	_expect(_state.save_progress(), "Repeated replacement can restore the expected saved profile")
	var prior: Dictionary = SaveData.read(test_path + ".bak")
	_expect(prior["ok"] and prior["data"].get("coins") == 69123,
		"Repeated saving keeps the previous valid profile in its backup")
	var saved: Dictionary = SaveData.read(test_path)
	_expect(saved["ok"] and saved["data"].get("version") == 1, "The saved profile has a readable version-one schema")
	if not saved["ok"]:
		_state.save_enabled = false
		return
	var valid: Dictionary = saved["data"].duplicate(true)
	var expected := _progress_snapshot()
	_state.save_enabled = false
	_state.reset_progress()
	_state.save_enabled = true
	_expect(_state.load_progress() and _progress_snapshot() == expected,
		"Local saving round-trips coins, XP, derived level, gems and completed customers")
	_expect(_state.selected_parts.is_empty() and _state.last_result.is_empty() and not _state.reward_claimed,
		"Loading progress starts a fresh attempt rather than restoring a payable result")
	_state.start_job("study")
	_select_parts("study")
	_state.evaluate_build()
	_expect(_state.claim_reward() and _state.coins == 74000 and _state.xp == 1600 and _state.gems == 55,
		"A loaded completed customer cannot earn another first-completion gem")
	var recoverable := _progress_snapshot()
	_state.coins += 321
	_expect(_state.save_progress(), "A newer profile leaves a recoverable previous save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	var backup_only: Dictionary = SaveData.read(test_path)
	_expect(backup_only["ok"] and backup_only["data"].get("coins") == 74000 and _state.load_progress() and _progress_snapshot() == recoverable,
		"A backup-only save loads when the primary file is missing")
	_write_text(test_path, "{broken primary with valid backup")
	_state.coins = 123
	_expect(SaveData.read(test_path)["ok"] and _state.load_progress() and _progress_snapshot() == recoverable,
		"A corrupt primary recovers the previous valid backup without losing that profile")
	# Rejection fixtures deliberately have no backup; otherwise recovery is valid.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".bak"))

	_expect(_write_text(test_path, "{broken json"), "The corrupt-save fixture uses only the isolated test path")
	var before_corrupt := _progress_snapshot()
	_expect(not SaveData.read(test_path)["ok"] and not _state.load_progress() and _progress_snapshot() == before_corrupt,
		"Malformed JSON is rejected without replacing progress")
	var invalid_values: Array[Dictionary] = [
		{"key": "version", "value": 2},
		{"key": "coins", "value": -1},
		{"key": "coins", "value": "100"},
		{"key": "coins", "value": true},
		{"key": "coins", "value": 1.5},
		{"key": "xp", "value": -1},
		{"key": "level", "value": 0},
		{"key": "gems", "value": -1},
		{"key": "gems", "value": null},
		{"key": "completed_jobs", "value": "study"},
		{"key": "completed_jobs", "value": ["unknown"]},
		{"key": "completed_jobs", "value": ["study", "study"]},
		{"key": "completed_jobs", "value": ["study", 2]},
	]
	for invalid in invalid_values:
		var data: Dictionary = valid.duplicate(true)
		data[invalid["key"]] = invalid["value"]
		_write_text(test_path, JSON.stringify(data))
		var before := _progress_snapshot()
		_expect(not SaveData.read(test_path)["ok"] and not _state.load_progress() and _progress_snapshot() == before,
			"Invalid saved %s value %s is rejected without altering progress" % [invalid["key"], str(invalid["value"])])
	var inconsistent: Dictionary = valid.duplicate(true)
	inconsistent["level"] = 999
	_write_text(test_path, JSON.stringify(inconsistent))
	_expect(_state.load_progress() and _state.xp == 1500 and _state.level == 6,
		"Loading derives level from XP rather than trusting an inconsistent saved level")
	# A file cannot act as a folder; this failure cannot modify the existing save.
	_state.save_path = test_path + "/nested.json"
	_expect(not _state.save_progress() and not _state.save_error.is_empty(),
		"A failed local save reports its error rather than claiming to save")
	_state.save_path = test_path
	_state.save_enabled = false


func _test_five_job_buttons() -> void:
	var previous_size: Vector2i = _tree.root.size
	var previous_scale_size: Vector2i = _tree.root.content_scale_size
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	for viewport_size in [Vector2i(1180, 780), Vector2i(360, 800), Vector2i(440, 900)]:
		_state.reset_progress()
		_tree.root.content_scale_size = viewport_size
		_tree.root.size = viewport_size
		var main: Node = main_scene.instantiate()
		_tree.root.add_child(main)
		await _frames()
		var locked: Button = main.find_child("Job_gaming", true, false) as Button
		_expect(locked != null and locked.disabled, "The job board visibly locks gaming before the first completion")
		if not await _press(main, "StartButton"):
			main.queue_free()
			return
		for index in range(JOB_IDS.size()):
			var job: JobData = JobsCatalog.find_job(JOB_IDS[index])
			var label: String = "%s at %d x %d" % [job.id, viewport_size.x, viewport_size.y]
			_expect(_state.current_job_id == job.id, "The button flow reaches the %s customer" % label)
			_layout(main, label + " request", ["AcceptButton", "MenuButton"])
			if not await _press(main, "AcceptButton"):
				main.queue_free()
				return
			_layout(main, label + " shop", ["ContinueButton", "BackButton"])
			if index == 0:
				var locked_part: Button = main.find_child("cpu_g8", true, false) as Button
				_expect(locked_part != null and locked_part.disabled, "The study shop visibly locks higher-level CPUs")
			for part_id in BUILD_IDS[job.id]:
				if not await _press(main, part_id):
					main.queue_free()
					return
			if not await _press(main, "ContinueButton"):
				main.queue_free()
				return
			_layout(main, label + " build", ["BuildButton", "EditPartsButton"])
			var before := _progress_snapshot()
			if not await _press(main, "BuildButton"):
				main.queue_free()
				return
			_expect(_state.last_result.get("success", false) and _progress_snapshot() == before,
				"The %s result succeeds without paying early" % label)
			_layout(main, label + " result", ["RewardButton"])
			if not await _press(main, "RewardButton"):
				main.queue_free()
				return
			_layout(main, label + " reward", ["ReplayButton", "MenuButton"])
			_expect(_state.coins == before["coins"] + job.reward_coins and _state.xp == before["xp"] + job.reward_xp and _state.gems == 51 + index and _state.level == index + 2,
				"The %s reward pays the correct currencies, XP and level" % label)
			_expect(_progress_wallet_matches(main), "The %s HUD shows saved progression values" % label)
			if index + 1 < JOB_IDS.size():
				if not await _press(main, "ReplayButton"):
					main.queue_free()
					return
		_expect(_state.completed_jobs.size() == 5 and _state.coins == 69000 and _state.xp == 1500 and _state.gems == 55,
			"The full five-customer button flow completes at %d x %d" % [viewport_size.x, viewport_size.y])
		if not await _press(main, "MenuButton"):
			main.queue_free()
			return
		var all_jobs_enabled: bool = true
		for job_id in JOB_IDS:
			var button: Button = main.find_child("Job_" + job_id, true, false) as Button
			all_jobs_enabled = all_jobs_enabled and button != null and not button.disabled
		_expect(all_jobs_enabled, "All five job-board buttons unlock after completing progression")
		main.queue_free()
		await _frames()
	_tree.root.size = previous_size
	_tree.root.content_scale_size = previous_scale_size
	await _frames()


func _parts(job_id: String) -> Dictionary:
	var parts: Dictionary = {}
	var ids: Array = BUILD_IDS[job_id]
	for index in range(PartsCatalog.CATEGORIES.size()):
		parts[PartsCatalog.CATEGORIES[index]] = PartsCatalog.find_part(ids[index])
	return parts


func _select_parts(job_id: String) -> void:
	var parts := _parts(job_id)
	for category in PartsCatalog.CATEGORIES:
		_state.select_part(category, parts[category])


func _progress_snapshot() -> Dictionary:
	return {
		"coins": _state.coins, "xp": _state.xp, "level": _state.level,
		"gems": _state.gems, "completed_jobs": _state.completed_jobs.duplicate(),
	}


func _progress_wallet_matches(main: Node) -> bool:
	for field in ["coins", "xp", "level", "gems"]:
		var label: Label = main.find_child(field.capitalize() + "Value" if field != "xp" else "XPValue", true, false) as Label
		if label == null or label.text != ScreenUI.money(_state.get(field)):
			return false
	return true


func _write_text(path: String, value: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.close()
	return true


func _expect_failure(result: Dictionary, reason: String, message: String) -> void:
	var includes_reason: bool = false
	for detail in result["reasons"]:
		includes_reason = includes_reason or reason in str(detail)
	_expect(not result["success"] and includes_reason, message)


func _layout(main: Node, label: String, buttons: Array[String]) -> void:
	_tree.call("_check_page_layout", main, label, buttons)


func _press(main: Node, button_name: String) -> bool:
	var button: Button = main.find_child(button_name, true, false) as Button
	_expect(button != null and not button.disabled, "The progression flow can press %s" % button_name)
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	await _frames()
	return true


func _frames() -> void:
	await _tree.process_frame
	await _tree.process_frame


func _expect(condition: bool, message: String) -> void:
	_report.call(condition, message)
