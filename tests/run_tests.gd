extends SceneTree
## Run with: godot --headless --path . --script res://tests/run_tests.gd
## These checks exercise the rules, reward safeguards, and the actual button flow.

const Catalog = preload("res://scripts/data/parts_catalog.gd")
const Validator = preload("res://scripts/build_validator.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1180, 780)
	await process_frame
	_test_catalog()
	_test_validation()
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload is available")
	if state != null:
		_test_rewards(state)
		await _test_scene_flow(state)
	print("\nPrototype tests: %d checks, %d failures." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_catalog() -> void:
	var seen_ids: Array[String] = []
	for category in Catalog.CATEGORIES:
		var parts: Array[PartData] = Catalog.get_parts(category)
		_check(parts.size() == 2, "Two options exist for %s" % category)
		for part in parts:
			_check(part.category == category, "%s belongs to its category" % part.id)
			_check(part.price > 0, "%s has a positive price" % part.id)
			_check(not seen_ids.has(part.id), "%s has a unique ID" % part.id)
			seen_ids.append(part.id)
			_check(Catalog.find_part(part.id) != null, "%s can be found by ID" % part.id)
	_check(seen_ids.size() == 10, "The prototype has ten parts")
	_check(Catalog.get_parts("unknown").is_empty(), "Unknown categories return no parts")
	_check(Catalog.find_part("unknown") == null, "Unknown IDs return no part")
	var first: PartData = Catalog.find_part("cpu_s4")
	first.price = 1
	_check(Catalog.find_part("cpu_s4").price == 12000, "Catalog resources are independent")


func _test_validation() -> void:
	var basic: Dictionary = _parts()
	var before: Dictionary = _snapshot(basic)
	var result: Dictionary = Validator.validate(basic, 60000)
	_check(result["success"], "The basic study PC succeeds")
	_check(result["reasons"].is_empty(), "A successful build has no failure reasons")
	_check(result["total_cost"] == 38000, "The basic PC costs 38,000 coins")
	_check(result["required_power"] == 139, "The basic PC needs 139 W including fixed overhead")
	_check(result["psu_wattage"] == 180, "The selected PSU supplies 180 W")
	_check(_snapshot(basic) == before, "Validation does not change selected resources")

	var socket_mismatch: Dictionary = _parts("cpu_p6", "board_a", "ram_ddr4", "ssd_256", "psu_350")
	_expect_failure(Validator.validate(socket_mismatch, 60000), "CPU / motherboard", "A mismatched CPU socket fails")
	var ram_mismatch: Dictionary = _parts("cpu_s4", "board_a", "ram_ddr5")
	_expect_failure(Validator.validate(ram_mismatch, 60000), "RAM / motherboard", "An unsupported RAM generation fails")
	var weak_psu: Dictionary = _parts("cpu_p6", "board_b", "ram_ddr5", "ssd_512", "psu_180")
	result = Validator.validate(weak_psu, 60000)
	_expect_failure(result, "PSU capacity", "A 180 W PSU cannot power the 208 W build")
	_check(result["total_cost"] == 59000, "The weak-PSU build stays within the customer budget")
	var expensive: Dictionary = _parts("cpu_p6", "board_b", "ram_ddr5", "ssd_512", "psu_350")
	result = Validator.validate(expensive, 60000)
	_expect_failure(result, "Customer budget", "The compatible 63,000-coin build exceeds the budget")
	_check(result["total_cost"] == 63000, "The expensive build costs 63,000 coins")
	_check(result["required_power"] == 208, "The expensive build requires 208 W")

	var exact_budget: Dictionary = _parts("cpu_p6", "board_b", "ram_ddr5", "ssd_256", "psu_350")
	result = Validator.validate(exact_budget, 60000)
	_check(result["success"] and result["total_cost"] == 60000, "A build exactly at the budget succeeds")
	var incomplete: Dictionary = _parts()
	incomplete.erase("ssd")
	_expect_failure(Validator.validate(incomplete, 60000), "Required parts", "A missing SSD cannot succeed")
	var wrong_slot: Dictionary = _parts()
	wrong_slot["cpu"] = Catalog.find_part("ram_ddr4")
	_expect_failure(Validator.validate(wrong_slot, 60000), "Required parts", "RAM cannot occupy the CPU slot")
	var unknown_slot: Dictionary = _parts()
	unknown_slot["extra"] = Catalog.find_part("ssd_256")
	_expect_failure(Validator.validate(unknown_slot, 60000), "Required parts", "An unknown slot cannot succeed")
	var unsupported_ssd: Dictionary = _parts()
	unsupported_ssd["ssd"].interface_type = "NVMe"
	_expect_failure(Validator.validate(unsupported_ssd, 60000), "SSD / motherboard", "An unsupported storage interface fails")

	var exact_power: Dictionary = _parts()
	exact_power["psu"].wattage = 139
	_check(Validator.validate(exact_power, 60000)["success"], "A PSU exactly meeting demand succeeds")
	exact_power["psu"].wattage = 138
	_expect_failure(Validator.validate(exact_power, 60000), "PSU capacity", "A PSU one watt short fails")


func _test_rewards(state: Node) -> void:
	var starting_coins: int = state.coins
	var starting_xp: int = state.xp
	state.start_new_request()
	_check(state.selected_parts.is_empty(), "A new request begins with no selected parts")
	_check(not state.has_all_parts(), "An empty build is incomplete")
	_check(not state.claim_reward(), "No reward can be claimed before building")
	_select_state_parts(state, _parts())
	_check(state.has_all_parts(), "Selecting five parts completes the build")
	_check(state.total_cost() == 38000, "GameState reports the chosen parts' cost")
	_check(state.evaluate_build()["success"], "GameState evaluates the valid build")
	_check(state.coins == starting_coins and state.xp == starting_xp, "Evaluating a build does not pay the reward")
	_check(state.claim_reward(), "The first successful reward claim succeeds")
	_check(state.coins == starting_coins + 5000 and state.xp == starting_xp + 100, "Success awards 5,000 coins and 100 XP")
	_check(not state.claim_reward(), "The same build cannot pay twice")
	_check(state.coins == starting_coins + 5000 and state.xp == starting_xp + 100, "A second claim leaves totals unchanged")

	state.start_new_request()
	_check(state.coins == starting_coins + 5000 and state.xp == starting_xp + 100, "Replaying preserves earned coins and XP")
	_check(state.selected_parts.is_empty() and state.last_result.is_empty(), "Replaying clears selections and results")
	_check(not state.reward_claimed, "Replaying resets the reward claim flag")
	_select_state_parts(state, _parts("cpu_s4", "board_a", "ram_ddr5"))
	_check(not state.evaluate_build()["success"], "GameState records a failed build")
	_check(not state.claim_reward(), "A failed build earns no reward")

	state.start_new_request()
	_select_state_parts(state, _parts())
	state.evaluate_build()
	state.select_part("ssd", Catalog.find_part("ssd_512"))
	_check(state.last_result.is_empty(), "Changing a selection invalidates the old result")
	_check(not state.claim_reward(), "An invalidated successful result cannot pay")
	state.evaluate_build()
	state.selected_parts["cpu"].socket = "changed_after_build"
	_check(not state.claim_reward(), "Editing a resource after building cannot pay a stale reward")
	state.start_new_request()
	_select_state_parts(state, _parts())
	state.evaluate_build()
	state.customer_budget = 37000
	_check(not state.claim_reward(), "Changing the budget invalidates a pending reward")
	state.customer_budget = 60000
	state.start_new_request()
	_check(state.coins == starting_coins + 5000 and state.xp == starting_xp + 100, "Rejected rewards leave player totals unchanged")


func _test_scene_flow(state: Node) -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "The main scene loads")
	if main_scene == null:
		return
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await _advance_frames()
	var viewport_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(root.size))
	var start_button: Button = main.find_child("StartButton", true, false) as Button
	_check(start_button != null and viewport_rect.encloses(start_button.get_global_rect()),
		"The main menu Start button is fully visible at 1180 x 780")
	var page_scroll: ScrollContainer = main.find_child("PageScroll", true, false) as ScrollContainer
	_check(page_scroll != null and page_scroll.size.y >= 350,
		"The menu has at least 350 pixels of usable page viewport")
	var coins_before: int = state.coins
	var xp_before: int = state.xp
	if not await _press_button(main, "StartButton"):
		return
	_check(_has_text(main, "60,000"), "The request shows the 60,000-coin budget")
	if not await _press_button(main, "AcceptButton"):
		return
	var continue_button: Button = main.find_child("ContinueButton", true, false) as Button
	_check(continue_button != null and continue_button.disabled, "An empty shop basket cannot continue to building")
	if not await _choose_shop_parts(main, _parts()):
		return
	if not await _press_button(main, "ContinueButton"):
		return
	var build_body: Control = main.find_child("PageBody", true, false) as Control
	_check(build_body != null and build_body.size.y < 1000,
		"The five selected parts fit in a readable build page under 1,000 pixels tall")
	_check(_has_text(main, "StudyChip S4"), "The build screen shows the selected CPU")
	if not await _press_button(main, "BuildButton"):
		return
	_check(_has_text(main, "SUCCESS"), "The result screen shows SUCCESS")
	_check(state.coins == coins_before and state.xp == xp_before, "The result screen leaves the reward for the reward step")
	if not await _press_button(main, "RewardButton"):
		return
	_check(state.coins == coins_before + 5000 and state.xp == xp_before + 100, "The reward screen pays coins and XP")
	_check(state.reward_claimed, "The reward screen records the claim")
	if not await _press_button(main, "MenuButton"):
		return
	_check(main.find_child("StartButton", true, false) != null, "The reward screen returns to the main menu")

	if not await _press_button(main, "StartButton"):
		return
	if not await _press_button(main, "AcceptButton"):
		return
	if not await _choose_shop_parts(main, _parts("cpu_s4", "board_a", "ram_ddr5")):
		return
	if not await _press_button(main, "ContinueButton"):
		return
	if not await _press_button(main, "BuildButton"):
		return
	_check(_has_text(main, "FAILURE"), "The result screen shows FAILURE")
	_check(_has_text(main, "RAM / motherboard"), "The failure screen explains the RAM incompatibility")
	_check(main.find_child("RewardButton", true, false) == null, "A failed result has no reward button")
	_check(state.coins == coins_before + 5000 and state.xp == xp_before + 100, "A failed UI build leaves rewards unchanged")
	if not await _press_button(main, "EditPartsButton"):
		return
	if not await _press_button(main, "ram_ddr4"):
		return
	if not await _press_button(main, "ContinueButton"):
		return
	if not await _press_button(main, "BuildButton"):
		return
	_check(_has_text(main, "SUCCESS"), "Correcting RAM lets the customer build succeed")
	main.queue_free()
	await _advance_frames()


func _parts(
	cpu_id: String = "cpu_s4", board_id: String = "board_a",
	ram_id: String = "ram_ddr4", ssd_id: String = "ssd_256", psu_id: String = "psu_180"
) -> Dictionary:
	return {
		"cpu": Catalog.find_part(cpu_id),
		"motherboard": Catalog.find_part(board_id),
		"ram": Catalog.find_part(ram_id),
		"ssd": Catalog.find_part(ssd_id),
		"psu": Catalog.find_part(psu_id),
	}


func _snapshot(parts: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for category in parts:
		var part: PartData = parts[category]
		snapshot[category] = [part.id, part.category, part.price, part.socket,
			part.ram_type, part.power_draw, part.wattage, part.capacity_gb,
			part.interface_type, part.supported_storage_interfaces.duplicate()]
	return snapshot


func _select_state_parts(state: Node, parts: Dictionary) -> void:
	for category in Catalog.CATEGORIES:
		state.select_part(category, parts[category])


func _expect_failure(result: Dictionary, reason_text: String, message: String) -> void:
	_check(not result["success"], message)
	var contains_reason: bool = false
	for reason in result["reasons"]:
		if reason_text in str(reason):
			contains_reason = true
	_check(contains_reason, "%s includes a clear reason" % message)


func _choose_shop_parts(main: Node, parts: Dictionary) -> bool:
	for category in Catalog.CATEGORIES:
		if not await _press_button(main, parts[category].id):
			return false
	return true


func _press_button(main: Node, button_name: String) -> bool:
	var button: Button = main.find_child(button_name, true, false) as Button
	_check(button != null, "The current screen contains %s" % button_name)
	if button == null:
		return false
	_check(not button.disabled, "%s is enabled" % button_name)
	if button.disabled:
		return false
	button.pressed.emit()
	await _advance_frames()
	return true


func _has_text(node: Node, text: String) -> bool:
	if node is Label or node is RichTextLabel:
		if text in node.text:
			return true
	for child in node.get_children():
		if _has_text(child, text):
			return true
	return false


func _advance_frames() -> void:
	# Screen swaps are deferred; allow the old screen to leave the tree.
	await process_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("TEST FAILED: " + message)
