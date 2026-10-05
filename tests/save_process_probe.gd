extends SceneTree
## Child-process probe. Refuses every path except its dedicated test filename.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2 or arguments[0] not in ["write", "read"]:
		_fail("Expected a save probe mode and isolated filename.")
		return
	var mode: String = arguments[0]
	var path: String = arguments[1]
	var filename: String = path.trim_prefix("user://")
	if not path.begins_with("user://pc_builder_process_test_") or not filename.ends_with(".json") or filename.contains("/") or filename.contains("\\") or filename.contains(".."):
		_fail("The save probe refuses a non-test path.")
		return
	var state: Node = root.get_node_or_null("GameState")
	if state == null or state.save_enabled:
		_fail("Normal save access must be disabled before running the probe.")
		return
	state.save_path = path
	var before_coins: int = state.coins
	if mode == "write":
		state.reset_progress()
		state.save_enabled = true
		for job_id in ["study", "gaming"]:
			if not state.start_job(job_id):
				_fail("The test customer could not start.")
				return
			var ids: Array = ["cpu_s4", "board_a", "ram_ddr4", "ssd_256", "psu_180"] if job_id == "study" else ["cpu_p6", "board_b", "ram_ddr5", "ssd_512", "psu_350"]
			for index in range(PartsCatalog.CATEGORIES.size()):
				state.select_part(PartsCatalog.CATEGORIES[index], PartsCatalog.find_part(ids[index]))
			if not state.evaluate_build()["success"] or not state.claim_reward() or not state.save_error.is_empty():
				_fail("A test customer reward could not be saved.")
				return
	else:
		if not state.load_progress() or not state.selected_parts.is_empty() or not state.last_result.is_empty():
			_fail("The isolated profile could not resume as a fresh attempt.")
			return
	if state.coins != 13000 or state.xp != 300 or state.level != 3 or state.gems != 52:
		_fail("The saved test progression does not match the two completed jobs.")
		return
	print("PROCESS_SAVE_RESULT:" + JSON.stringify({
		"pid": OS.get_process_id(), "before_coins": before_coins,
		"coins": state.coins, "xp": state.xp, "level": state.level, "gems": state.gems,
		"completed_jobs": Array(state.completed_jobs), "current_job_id": state.current_job_id,
	}))
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
