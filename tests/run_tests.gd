extends SceneTree
## Run with: godot --headless --path . --script res://tests/run_tests.gd
## These checks exercise the rules, reward safeguards, and the actual button flow.

const Catalog = preload("res://scripts/data/parts_catalog.gd")
const Validator = preload("res://scripts/build_validator.gd")
const ART_PATHS: Dictionary = {
	"cpu": "res://assets/icons/cpu.png",
	"motherboard": "res://assets/icons/motherboard.png",
	"ram": "res://assets/icons/ram.png",
	"ssd": "res://assets/icons/ssd.png",
	"psu": "res://assets/icons/psu.png",
	"mika": "res://assets/characters/mika.png",
	"workshop": "res://assets/backgrounds/workshop_room.png",
}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1180, 780)
	root.content_scale_size = root.size
	await process_frame
	_test_catalog()
	_test_validation()
	_test_art_assets()
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload is available")
	if state != null:
		_test_rewards(state)
		_test_deselection(state)
		await _test_pc_build_slots(state)
		await _test_scene_flow(state)
		await _test_responsive_pages(state)
		await _test_art_pages(state)
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
	var first_board: PartData = Catalog.find_part("board_a")
	first_board.supported_storage_interfaces.append("NVMe")
	_check(Catalog.find_part("board_a").supported_storage_interfaces == PackedStringArray(["SATA"]),
		"Editing a motherboard's storage interfaces cannot change the catalog")
	var default_part := PartData.new()
	_check(typeof(default_part.supported_storage_interfaces) == TYPE_PACKED_STRING_ARRAY,
		"Default storage interfaces are a PackedStringArray")
	_check(default_part.supported_storage_interfaces.duplicate().is_empty(),
		"Default storage interfaces can be copied safely")
	_check(Catalog.find_part("cpu_s4").supported_storage_interfaces.duplicate().is_empty(),
		"Parts without storage specifications have a safely copied empty array")


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
	state.select_part("ssd", null)
	_check(state.reward_claimed, "Deselecting after payment preserves the request's claimed reward")
	state.select_part("ssd", Catalog.find_part("ssd_512"))
	_check(state.evaluate_build()["success"], "A paid request can still evaluate an edited valid build")
	_check(not state.claim_reward(), "Editing and rebuilding a paid request cannot pay again")

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
	_select_state_parts(state, _parts())
	state.evaluate_build()
	state.selected_parts["motherboard"].supported_storage_interfaces.append("NVMe")
	_check(Validator.validate(state.selected_parts, state.customer_budget)["success"],
		"Adding a storage interface leaves the evaluated parts compatible")
	_check(not state.claim_reward(), "Changing a storage interface array cannot claim the previous result")
	state.start_new_request()
	_select_state_parts(state, _parts())
	state.evaluate_build()
	state.selected_parts["cpu"].price += 1
	_check(Validator.validate(state.selected_parts, state.customer_budget)["success"],
		"A one-coin price change still leaves the parts within budget")
	_check(not state.claim_reward(), "Changing a price cannot claim the previous result even if the build remains valid")
	state.start_new_request()
	_check(state.coins == starting_coins + 5000 and state.xp == starting_xp + 100, "Rejected rewards leave player totals unchanged")


func _test_deselection(state: Node) -> void:
	state.start_new_request()
	state.select_part("cpu", PartData.new("default_cpu", "cpu"))
	_check(not state.evaluate_build()["success"],
		"An incomplete build with default storage interfaces evaluates safely")
	state.start_new_request()
	_select_state_parts(state, _parts())
	state.evaluate_build()
	var before: Dictionary = _snapshot(state.selected_parts)
	var notifications: Array[int] = [0]
	var on_change := func() -> void:
		notifications[0] += 1
	state.state_changed.connect(on_change)
	state.select_part("unknown", null)
	state.select_part("unknown", Catalog.find_part("ssd_512"))
	state.select_part("ssd", Catalog.find_part("ram_ddr4"))
	_check(_snapshot(state.selected_parts) == before, "Invalid selection and deselection requests leave all slots unchanged")
	_check(state.last_result.get("success", false), "Invalid selection requests preserve the evaluated result")
	_check(notifications[0] == 0, "Invalid selection requests emit no state change")
	state.select_part("ssd", null)
	_check(not state.selected_parts.has("ssd"), "Deselecting removes the SSD slot")
	_check(state.total_cost() == 33000, "Deselecting removes the SSD's price from the total")
	_check(Validator.required_power(state.selected_parts) == 135, "Deselecting removes the SSD's power draw while retaining case overhead")
	_check(not state.has_all_parts(), "Deselecting makes the build incomplete")
	_check(state.last_result.is_empty(), "Deselecting invalidates the evaluated result")
	_check(not state.claim_reward(), "A deselected build cannot claim a stale reward")
	_check(notifications[0] == 1, "Deselecting an occupied slot emits one state change")
	state.select_part("ssd", null)
	_check(notifications[0] == 1, "Deselecting an empty slot is a silent no-op")
	state.state_changed.disconnect(on_change)
	state.start_new_request()


func _test_pc_build_slots(state: Node) -> void:
	var build_scene: PackedScene = load("res://scenes/screens/pc_build.tscn")
	for has_cpu in [false, true]:
		state.start_new_request()
		if has_cpu:
			state.select_part("cpu", Catalog.find_part("cpu_s4"))
		var build: Node = build_scene.instantiate()
		root.add_child(build)
		await _advance_frames()
		var title: Label = _find_label(build, "Selected components")
		var separators: int = 0
		if title != null:
			for child in title.get_parent().get_children():
				if child is HSeparator:
					separators += 1
		_check(title != null and separators == 4, "An %s build keeps four separators between its five component slots" % ["incomplete" if has_cpu else "empty"])
		_check(_has_text(build, "SSD: no part selected"), "An incomplete build identifies the empty SSD slot")
		_check(_has_text(build, "PSU: no part selected"), "An incomplete build identifies the empty PSU slot")
		_check(_has_text(build, "Selected PSU: no part selected"), "An incomplete build's summary reports the absent PSU")
		var build_button: Button = build.find_child("BuildButton", true, false) as Button
		_check(build_button != null and build_button.disabled, "An incomplete build cannot press Build PC")
		build.queue_free()
		await _advance_frames()
	state.start_new_request()


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
	if not await _press_button(main, "ssd_256"):
		return
	_check(not state.selected_parts.has("ssd"), "Clicking the selected shop option deselects its component")
	_check(continue_button.disabled, "Deselecting in the shop disables Continue")
	var ssd_choice: Button = main.find_child("ssd_256", true, false) as Button
	_check(ssd_choice != null and not ssd_choice.button_pressed, "The deselected shop option is visibly unpressed")
	if not await _press_button(main, "ssd_256"):
		return
	_check(state.has_all_parts() and not continue_button.disabled, "Clicking the shop option again restores the complete basket")
	if not await _press_button(main, "ContinueButton"):
		return
	var build_body: Control = main.find_child("PageBody", true, false) as Control
	_check(build_body != null and build_body.size.y < 1000,
		"The five selected parts fit in a readable build page under 1,000 pixels tall")
	_check(_has_text(main, "StudyChip S4"), "The build screen shows the selected CPU")
	_check(_has_text(main, "Selected PSU: StudyPower 180 W | Supplies up to 180 W"),
		"The build summary identifies the selected PSU model and capacity")
	var first_build_id: int = main.get("current_screen").get_instance_id()
	if not await _press_button(main, "EditPartsButton"):
		return
	if not await _press_button(main, "ssd_512"):
		return
	if not await _press_button(main, "ContinueButton"):
		return
	_check(main.get("current_screen").get_instance_id() != first_build_id,
		"Returning from the shop creates a fresh PC build screen")
	_check(_has_text(main, "StudySSD 512 GB"), "The recreated build screen shows the replacement SSD")
	_check(not _has_text(main, "StudySSD 256 GB"), "The recreated build screen does not show the previous SSD")
	_check(_has_text(main, "Total cost: 41,000 / 60,000 coins"), "Returning from the shop refreshes the build cost")
	_check(_has_text(main, "Estimated power needed: 140 W"), "Returning from the shop refreshes the build power")
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


func _test_responsive_pages(state: Node) -> void:
	# Exercise the logical viewport at phone sizes, rather than scaling a PC page.
	var previous_scale_size: Vector2i = root.content_scale_size
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	for viewport_size in [Vector2i(360, 800), Vector2i(440, 900)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		var main: Node = main_scene.instantiate()
		root.add_child(main)
		await _advance_frames()
		await _run_portrait_flow(main, state, viewport_size)
		main.queue_free()
		await _advance_frames()
	root.size = Vector2i(1180, 780)
	root.content_scale_size = previous_scale_size
	await _advance_frames()


func _run_portrait_flow(main: Node, state: Node, viewport_size: Vector2i) -> void:
	var size_name: String = "%d x %d" % [viewport_size.x, viewport_size.y]
	_check_page_layout(main, "%s menu" % size_name, ["StartButton", "QuitButton"])
	_test_wallet_updates(main, state)
	if not await _press_button(main, "StartButton"):
		return
	_check_page_layout(main, "%s request" % size_name, ["AcceptButton", "MenuButton"])
	_check(_has_text(main, "60,000"), "The portrait request shows the customer budget")
	if not await _press_button(main, "AcceptButton"):
		return
	_check_page_layout(main, "%s shop" % size_name, ["ContinueButton", "BackButton"])
	_check(_choice_grids_have_columns(main, 1), "The %s shop puts part choices in one column" % size_name)
	if not await _choose_shop_parts(main, _parts()):
		return
	_check(_selected_choices_have_badges(main, state), "Selected portrait shop cards have an explicit SELECTED badge")
	if viewport_size.x == 360:
		var shop_id: int = main.get("current_screen").get_instance_id()
		var selection_before: Dictionary = _snapshot(state.selected_parts)
		root.content_scale_size = Vector2i(1180, 780)
		root.size = Vector2i(1180, 780)
		await _advance_frames()
		_check(_choice_grids_have_columns(main, 2), "Resizing the shop to desktop puts choices in two columns")
		_check_page_layout(main, "resized desktop shop", ["ContinueButton", "BackButton"])
		root.content_scale_size = viewport_size
		root.size = viewport_size
		await _advance_frames()
		_check(_choice_grids_have_columns(main, 1), "Resizing the shop back to portrait restores one column")
		_check(main.get("current_screen").get_instance_id() == shop_id and _snapshot(state.selected_parts) == selection_before,
			"Responsive reflow preserves the same screen instance and all selected parts")
		_check(_selected_choices_have_badges(main, state), "Selected badges remain correct after resizing")
	var coins_before: int = state.coins
	var xp_before: int = state.xp
	if not await _press_button(main, "ContinueButton"):
		return
	_check_page_layout(main, "%s PC build" % size_name, ["BuildButton", "EditPartsButton"])
	_check(_has_text(main, "38,000") and _has_text(main, "139 W"), "The portrait build shows the correct cost and power")
	if not await _press_button(main, "BuildButton"):
		return
	_check_page_layout(main, "%s success result" % size_name, ["RewardButton"])
	_check(_has_colored_label(main, "SUCCESS", ScreenUI.ACCENT), "A successful portrait result has a green SUCCESS status")
	if not await _press_button(main, "RewardButton"):
		return
	_check_page_layout(main, "%s reward" % size_name, ["ReplayButton", "MenuButton"])
	_check(state.coins == coins_before + 5000 and state.xp == xp_before + 100, "Completing the portrait flow pays the existing reward")
	_check(_wallet_matches_state(main, state), "The portrait reward screen's wallet shows the updated coins and XP")
	if not await _press_button(main, "ReplayButton"):
		return
	if not await _press_button(main, "AcceptButton"):
		return
	if not await _choose_shop_parts(main, _parts("cpu_s4", "board_a", "ram_ddr5")):
		return
	if not await _press_button(main, "ContinueButton"):
		return
	if not await _press_button(main, "BuildButton"):
		return
	_check_page_layout(main, "%s failure result" % size_name, ["EditPartsButton"])
	_check(_has_colored_label(main, "FAILURE", ScreenUI.DANGER), "A failed portrait result has a red FAILURE status")
	_check(_has_text(main, "RAM / motherboard") and main.find_child("RewardButton", true, false) == null,
		"A portrait failure explains the RAM mismatch and offers no reward")
	_check(state.coins == coins_before + 5000 and state.xp == xp_before + 100, "A failed portrait build leaves earned rewards unchanged")
	if not await _press_button(main, "EditPartsButton"):
		return
	_check_page_layout(main, "%s return to shop" % size_name, ["ContinueButton", "BackButton"])
	_check(_selected_choices_have_badges(main, state), "Returning from a failed portrait build preserves selected cards")


func _test_art_assets() -> void:
	for key in ART_PATHS:
		var path: String = ART_PATHS[key]
		_check(ResourceLoader.exists(path), "%s art exists at its normalized PNG path" % key)
		var texture: Texture2D = load(path) as Texture2D
		_check(texture != null, "%s art imports as a Texture2D" % key)
		if texture == null:
			continue
		var cached: Texture2D
		var limit: int = 256
		if key == "mika":
			cached = ArtAssets.MIKA
			limit = 512
		elif key == "workshop":
			cached = ArtAssets.WORKSHOP
			limit = 1280
		else:
			cached = ArtAssets.component_icon(key)
		_check(cached == texture, "%s art uses the shared cached texture" % key)
		_check(texture.get_width() > 0 and texture.get_height() > 0 and texture.get_width() <= limit and texture.get_height() <= limit,
			"%s imported texture stays within its %d-pixel limit" % [key, limit])
		# Compare with the source PNG without loading it as a runtime resource.
		var source := Image.new()
		var source_error: Error = source.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		var imported_aspect: float = float(texture.get_width()) / texture.get_height()
		var source_aspect: float = float(source.get_width()) / maxi(1, source.get_height())
		_check(source_error == OK and not source.is_empty() and absf(imported_aspect - source_aspect) < 0.01,
			"%s texture import preserves the source aspect ratio" % key)


func _test_art_pages(state: Node) -> void:
	# Keep the original fast button flow unchanged. These extra checks wait only
	# when they inspect the final appearance of a short entry animation.
	var previous_size: Vector2i = root.size
	var previous_scale_size: Vector2i = root.content_scale_size
	for viewport_size in [Vector2i(1180, 780), Vector2i(360, 800), Vector2i(440, 900)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		state.start_new_request()
		var menu: Control = load("res://scenes/screens/main_menu.tscn").instantiate()
		root.add_child(menu)
		await _advance_frames()
		_check_workshop_background(menu)
		menu.queue_free()
		await _advance_frames()

		var request: Control = load("res://scenes/screens/customer_request.tscn").instantiate()
		root.add_child(request)
		await _advance_frames()
		await create_timer(0.3).timeout
		_check_workshop_background(request)
		_check_customer_portrait(request, state)
		request.queue_free()
		await _advance_frames()

		_select_state_parts(state, _parts())
		var shop: Control = load("res://scenes/screens/parts_shop.tscn").instantiate()
		root.add_child(shop)
		await _advance_frames()
		_check_part_icons(shop)
		await _test_selection_motion(shop, state)
		shop.queue_free()
		await _advance_frames()

		for success in [true, false]:
			state.start_new_request()
			_select_state_parts(state, _parts() if success else _parts("cpu_s4", "board_a", "ram_ddr5"))
			state.evaluate_build()
			var result: Control = load("res://scenes/screens/result_screen.tscn").instantiate()
			root.add_child(result)
			await _advance_frames()
			await _check_result_motion(result, success)
			result.queue_free()
			await _advance_frames()
	state.start_new_request()
	root.size = previous_size
	root.content_scale_size = previous_scale_size
	await _advance_frames()


func _check_workshop_background(page: Control) -> void:
	var background: TextureRect = page.find_child("WorkshopBackground", true, false) as TextureRect
	var overlay: ColorRect = page.find_child("WorkshopOverlay", true, false) as ColorRect
	_check(background != null and background.texture == ArtAssets.WORKSHOP and background.expand_mode == TextureRect.EXPAND_IGNORE_SIZE and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED,
		"The workshop background fills the page while preserving its aspect ratio")
	_check(background != null and overlay != null and background.mouse_filter == Control.MOUSE_FILTER_IGNORE and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"The workshop art and dark overlay leave UI input available")
	_check(overlay != null and overlay.color.a >= 0.65 and overlay.color.a <= 0.9 and overlay.get_global_rect().encloses(Rect2(Vector2.ZERO, Vector2(root.size))),
		"A full-page dark overlay keeps workshop text readable")


func _check_customer_portrait(page: Control, state: Node) -> void:
	var portrait: TextureRect = page.find_child("MikaPortrait", true, false) as TextureRect
	var frame: Control = page.find_child("PortraitFrame", true, false) as Control
	var details: Control = page.find_child("CustomerDetails", true, false) as Control
	var request_text: Label = _find_label(page, state.customer_request)
	_check(portrait != null and portrait.texture == ArtAssets.MIKA and portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and portrait.expand_mode == TextureRect.EXPAND_IGNORE_SIZE and portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Mika's portrait uses the cached art without stretching or taking input")
	_check(frame != null and portrait != null and frame.get_global_rect().encloses(portrait.get_global_rect()) and portrait.modulate.a >= 0.99,
		"Mika's short entrance settles inside the portrait frame")
	_check(frame != null and details != null and not frame.get_global_rect().intersects(details.get_global_rect()) and request_text != null and request_text.get_global_rect().position.y >= frame.get_global_rect().end.y - 1,
		"The portrait does not overlap Mika's details or customer request")
	var scroll: ScrollContainer = page.find_child("PageScroll", true, false) as ScrollContainer
	var body: Control = page.find_child("PageBody", true, false) as Control
	_check(scroll != null and body != null and _content_fits_width(body, scroll.get_global_rect()),
		"The illustrated customer request fits the current page width")


func _check_part_icons(shop: Control) -> void:
	var correct_textures: bool = true
	var safe_display: bool = true
	for category in Catalog.CATEGORIES:
		var expected: Texture2D = ArtAssets.component_icon(category)
		for part in Catalog.get_parts(category):
			var choice: Button = shop.find_child(part.id, true, false) as Button
			var icon: TextureRect = choice.find_child("PartIcon", true, false) as TextureRect if choice != null else null
			if icon == null:
				correct_textures = false
				safe_display = false
				continue
			correct_textures = correct_textures and icon.texture == expected
			safe_display = safe_display and icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and icon.expand_mode == TextureRect.EXPAND_IGNORE_SIZE and icon.mouse_filter == Control.MOUSE_FILTER_IGNORE and icon.size.x <= 64 and icon.size.y <= 64
	_check(correct_textures, "All ten part cards use the correct shared category icon texture")
	_check(safe_display, "Part icons stay small, preserve aspect ratio, and leave button input available")


func _test_selection_motion(shop: Control, state: Node) -> void:
	var first: Button = shop.find_child("cpu_s4", true, false) as Button
	var other: Button = shop.find_child("cpu_p6", true, false) as Button
	_check(first != null and other != null, "Both CPU cards are available for rapid selection")
	if first == null or other == null:
		return
	var first_bounds: Rect2 = first.get_global_rect()
	var other_bounds: Rect2 = other.get_global_rect()
	# Each signal is handled immediately, even if the previous pop is active.
	for choice in [first, first, other, first, first, first]:
		choice.pressed.emit()
	var selected: PartData = state.selected_parts.get("cpu")
	_check(selected != null and selected.id == "cpu_s4" and first.button_pressed and not other.button_pressed,
		"Rapid selection and deselection leaves the last requested CPU selected")
	await create_timer(0.25).timeout
	var icons_settled: bool = true
	for icon in shop.find_children("PartIcon", "TextureRect", true, false):
		icons_settled = icons_settled and icon.scale.is_equal_approx(Vector2.ONE)
	_check(icons_settled and _selected_choices_have_badges(shop, state),
		"Selection pops settle at normal scale with the correct selected badges")
	_check(first.get_global_rect().is_equal_approx(first_bounds) and other.get_global_rect().is_equal_approx(other_bounds),
		"Selection animations keep both CPU button bounds unchanged")


func _check_result_motion(page: Control, success: bool) -> void:
	var banner: Control = page.find_child("ResultBanner", true, false) as Control
	var action: Button = page.find_child("RewardButton" if success else "EditPartsButton", true, false) as Button
	_check(banner != null and action != null and not action.disabled,
		"The %s report has an enabled action during its entrance" % ["success" if success else "failure"])
	if banner == null:
		return
	var before: Rect2 = banner.get_global_rect()
	await create_timer(0.25).timeout
	_check(banner.modulate.a >= 0.99 and banner.get_global_rect().is_equal_approx(before),
		"The %s report fades in without moving its banner" % ["success" if success else "failure"])


func _check_page_layout(main: Node, page_name: String, button_names: Array[String]) -> void:
	var scroll: ScrollContainer = main.find_child("PageScroll", true, false) as ScrollContainer
	var body: Control = main.find_child("PageBody", true, false) as Control
	_check(scroll != null and body != null and scroll.size.y >= 180 and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"%s has a usable vertical page viewport" % page_name)
	var footer_fits: bool = scroll != null
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	for button_name in button_names:
		var action: Button = main.find_child(button_name, true, false) as Button
		if action == null or action.size.y < 56 or not viewport_rect.encloses(action.get_global_rect()) or (scroll != null and scroll.is_ancestor_of(action)):
			footer_fits = false
			if action != null:
				print("Footer bounds: %s %s in %s" % [button_name, action.get_global_rect(), viewport_rect])
	_check(footer_fits, "%s keeps its large action buttons visible outside the scrolling content" % page_name)
	_check(scroll != null and body != null and _content_fits_width(body, scroll.get_global_rect()),
		"%s content fits the page width without horizontal overflow" % page_name)


func _content_fits_width(node: Node, bounds: Rect2) -> bool:
	if node is Control and node.is_visible_in_tree():
		var rectangle: Rect2 = node.get_global_rect()
		if rectangle.position.x < bounds.position.x - 1 or rectangle.end.x > bounds.end.x + 1:
			print("Layout overflow: %s %s in %s" % [node.get_path(), rectangle, bounds])
			return false
	for child in node.get_children():
		if not _content_fits_width(child, bounds):
			return false
	return true


func _choice_grids_have_columns(main: Node, expected_columns: int) -> bool:
	var grids: Array[Node] = main.find_children("*", "GridContainer", true, false)
	if grids.size() != Catalog.CATEGORIES.size():
		return false
	for grid in grids:
		if grid.columns != expected_columns:
			return false
	return true


func _selected_choices_have_badges(main: Node, state: Node) -> bool:
	for category in Catalog.CATEGORIES:
		var part: PartData = state.selected_parts.get(category)
		if part == null:
			return false
		var choice: Button = main.find_child(part.id, true, false) as Button
		var selected_label: Label = _find_label(choice, "SELECTED") if choice != null else null
		if choice == null or not choice.button_pressed or selected_label == null or not selected_label.is_visible_in_tree():
			return false
	return true


func _test_wallet_updates(main: Node, state: Node) -> void:
	_check(_wallet_matches_state(main, state), "The shared wallet displays current coins and XP")
	var coins_before: int = state.coins
	var xp_before: int = state.xp
	state.coins += 1234
	state.xp += 7
	state.state_changed.emit()
	_check(_wallet_matches_state(main, state), "The shared wallet refreshes on GameState.state_changed")
	state.coins = coins_before
	state.xp = xp_before
	state.state_changed.emit()


func _wallet_matches_state(main: Node, state: Node) -> bool:
	var hud: Node = main.find_child("PlayerHUD", true, false)
	if hud == null:
		return false
	var coins_value: Label = hud.find_child("CoinsValue", true, false) as Label
	var xp_value: Label = hud.find_child("XPValue", true, false) as Label
	return coins_value != null and xp_value != null and coins_value.text == ScreenUI.money(state.coins) and xp_value.text == ScreenUI.money(state.xp)


func _has_colored_label(node: Node, text: String, color: Color) -> bool:
	if node is Label and node.text == text and node.get_theme_color("font_color").is_equal_approx(color):
		return true
	for child in node.get_children():
		if _has_colored_label(child, text, color):
			return true
	return false


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


func _find_label(node: Node, text: String) -> Label:
	if node is Label and node.text == text:
		return node
	for child in node.get_children():
		var label: Label = _find_label(child, text)
		if label != null:
			return label
	return null


func _advance_frames() -> void:
	# Screen swaps are deferred; allow the old screen to leave the tree.
	await process_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("TEST FAILED: " + message)
