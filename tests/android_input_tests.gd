extends RefCounted
## Desktop engine checks of native touch events and separate-process local saves.
## These checks do not replace testing an exported APK on an Android device.

var _tree: SceneTree
var _state: Node
var _report: Callable


func run(tree: SceneTree, state: Node, report: Callable) -> void:
	_tree = tree
	_state = state
	_report = report
	_expect(Input.emulate_mouse_from_touch and not Input.emulate_touch_from_mouse,
		"Project input settings turn native touches into button clicks without duplicate touch emulation")
	_expect(ProjectSettings.get_setting("display/window/handheld/orientation") == 1,
		"The Android window requests portrait orientation")
	var presets := ConfigFile.new()
	var preset_loaded: bool = presets.load("res://export_presets.cfg") == OK
	_expect(preset_loaded, "Android export configuration can be read")
	if preset_loaded:
		# Godot 4.7 stores the chosen runnable preset in its own section when the
		# editor resaves exports. Older presets keep the flag on preset.0 instead.
		var preset_name: String = str(presets.get_value("preset.0", "name", ""))
		var runnable: bool = bool(presets.get_value("preset.0", "runnable", false))
		if presets.has_section_key("runnable_presets", "Android"):
			runnable = not preset_name.is_empty() and presets.get_value("runnable_presets", "Android", "") == preset_name
		_expect(presets.get_value("preset.0", "platform", "") == "Android" and runnable,
			"The runnable test export targets Android")
		_expect(presets.get_value("preset.0", "export_filter", "") == "all_resources",
			"The Android export includes dynamically loaded gameplay resources")
		var exclusions: PackedStringArray = str(presets.get_value("preset.0", "exclude_filter", "")).split(",")
		_expect(exclusions.has("tests/*") and exclusions.has("docs/*") and exclusions.has("README.md"),
			"The Android game package excludes test helpers and documentation")
	var previous_size: Vector2i = tree.root.size
	var previous_scale_size: Vector2i = tree.root.content_scale_size
	for viewport_size in [Vector2i(360, 800), Vector2i(440, 900)]:
		_state.reset_progress()
		tree.root.content_scale_size = viewport_size
		tree.root.size = viewport_size
		var main: Node = load("res://scenes/main.tscn").instantiate()
		tree.root.add_child(main)
		await _frames()
		await _test_phone_input(main, viewport_size)
		main.queue_free()
		await _frames()
	tree.root.size = previous_size
	tree.root.content_scale_size = previous_scale_size
	_state.reset_progress()
	await _frames()
	_test_process_restart()


func _test_phone_input(main: Node, viewport_size: Vector2i) -> void:
	var profile: String = "%d x %d" % [viewport_size.x, viewport_size.y]
	_check_targets_and_width(main, profile + " menu")
	await _test_customer_button_swipe(main, profile)
	if not await _tap_button(main, "StartButton"):
		return
	_expect(main.get("current_screen_name") == "customer_request", "A native finger tap opens the %s customer request" % profile)
	if main.get("current_screen_name") != "customer_request":
		return
	_check_targets_and_width(main, profile + " request")
	if not await _tap_button(main, "AcceptButton"):
		return
	_expect(main.get("current_screen_name") == "parts_shop", "A native finger tap accepts the %s customer request" % profile)
	if main.get("current_screen_name") != "parts_shop":
		return
	_check_targets_and_width(main, profile + " shop")
	var scroll: ScrollContainer = main.find_child("PageScroll", true, false) as ScrollContainer
	var cpu: Button = main.find_child("cpu_s4", true, false) as Button
	if scroll == null or cpu == null:
		_expect(false, "The native touch shop exposes its page and first CPU")
		return
	# Bring the target into view without changing game state. The interaction
	# itself goes through Input, the viewport, and the native Button handler.
	scroll.ensure_control_visible(cpu)
	await _frames()
	if not await _tap_button(main, "cpu_s4"):
		return
	var selected: PartData = _state.selected_parts.get("cpu")
	_expect(selected != null and selected.id == "cpu_s4" and cpu.button_pressed,
		"A native finger tap selects exactly one CPU at %s" % profile)
	if not await _tap_button(main, "cpu_s4"):
		return
	_expect(not _state.selected_parts.has("cpu") and not cpu.button_pressed,
		"A second native finger tap deselects the CPU at %s" % profile)
	var before: int = scroll.scroll_vertical
	var start: Vector2 = cpu.get_global_rect().get_center()
	# The endpoint stays inside the original card; scrolling must cancel the
	# pending button press instead of relying on the finger leaving its bounds.
	_expect(cpu.get_global_rect().has_point(start + Vector2(0, -80)),
		"The short %s shop swipe ends within the original component card" % profile)
	await _swipe_with_touchscreen(start, Vector2(0, -80), profile + " shop")
	_expect(scroll.scroll_vertical > before + 24 and scroll.scroll_horizontal == 0,
		"A native finger swipe scrolls the %s shop vertically" % profile)
	_expect(_state.selected_parts.is_empty(),
		"Swiping over a component card does not accidentally select it at %s" % profile)
	_check_targets_and_width(main, profile + " swiped shop")
	# Complete the same study request using native taps, including the sticky
	# action buttons on the remaining phone screens.
	for part_id in ["cpu_s4", "board_a", "ram_ddr4", "ssd_256", "psu_180"]:
		var choice: Button = main.find_child(part_id, true, false) as Button
		scroll.ensure_control_visible(choice)
		await _frames()
		if not await _tap_button(main, part_id):
			return
	_expect(_state.has_all_parts(), "Native taps choose the five study parts at %s" % profile)
	for transition in [["ContinueButton", "pc_build"], ["BuildButton", "result_screen"], ["RewardButton", "reward"]]:
		if not await _tap_button(main, transition[0]):
			return
		_expect(main.get("current_screen_name") == transition[1],
			"A native tap reaches the %s phone screen at %s" % [transition[1], profile])
		_check_targets_and_width(main, profile + " " + transition[1])
	_expect(_state.coins == 5000 and _state.xp == 100 and _state.gems == 51,
		"The native phone flow awards the study reward exactly once at %s" % profile)
	if await _tap_button(main, "MenuButton"):
		_expect(main.get("current_screen_name") == "main_menu",
			"A native tap returns from reward to the phone menu at %s" % profile)


func _test_customer_button_swipe(main: Node, profile: String) -> void:
	var scroll: ScrollContainer = main.find_child("PageScroll", true, false) as ScrollContainer
	var button: Button = main.find_child("Job_study", true, false) as Button
	scroll.ensure_control_visible(button)
	await _frames()
	var rectangle: Rect2 = button.get_global_rect()
	var start := Vector2(rectangle.get_center().x, rectangle.end.y - 8)
	var movement := Vector2(0, -minf(40, rectangle.size.y - 16))
	var before: int = scroll.scroll_vertical
	var clicks: Array[int] = [0]
	var record := func() -> void: clicks[0] += 1
	button.pressed.connect(record)
	_expect(rectangle.has_point(start + movement),
		"The short %s menu swipe ends within the same customer button" % profile)
	await _swipe_with_touchscreen(start, movement, profile + " menu")
	if is_instance_valid(button):
		button.pressed.disconnect(record)
	_expect(is_instance_valid(scroll) and scroll.scroll_vertical > before + 3,
		"A native swipe over the %s customer button scrolls the job board" % profile)
	_expect(clicks[0] == 0 and main.get("current_screen_name") == "main_menu",
		"Swiping inside the %s customer button does not open a request" % profile)
	_check_targets_and_width(main, profile + " swiped menu")


func _swipe_with_touchscreen(start: Vector2, movement: Vector2, name: String) -> void:
	# Godot 4.7's ScrollContainer requires a touchscreen display capability.
	# Android reports one; desktop/headless displays require test emulation.
	# This changes only the test process during the swipe, not project settings
	# or UI filters. Native events still enter through Input.parse_input_event.
	var previous_emulation: bool = Input.emulate_touch_from_mouse
	if not DisplayServer.is_touchscreen_available():
		Input.emulate_touch_from_mouse = true
	_expect(DisplayServer.is_touchscreen_available(),
		"The %s swipe has a real or simulated touchscreen capability" % name)
	await _finger_drag(start, movement)
	Input.emulate_touch_from_mouse = previous_emulation
	_expect(not Input.emulate_touch_from_mouse,
		"The %s swipe restores the project's normal input settings" % name)


func _tap_button(main: Node, button_name: String) -> bool:
	var button: Button = main.find_child(button_name, true, false) as Button
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(_tree.root.size))
	_expect(button != null and not button.disabled and viewport_rect.has_point(button.get_global_rect().get_center()),
		"The native touch target %s is enabled and on screen" % button_name)
	if button == null or button.disabled or not viewport_rect.has_point(button.get_global_rect().get_center()):
		return false
	var clicks: Array[int] = [0]
	var record_click := func() -> void:
		clicks[0] += 1
	button.pressed.connect(record_click)
	var point: Vector2 = button.get_global_rect().get_center()
	_send_touch(point, true)
	await _frames()
	_send_touch(point, false)
	await _frames()
	if is_instance_valid(button):
		button.pressed.disconnect(record_click)
	_expect(clicks[0] == 1, "Native touch press and release activate %s exactly once" % button_name)
	return clicks[0] == 1


func _finger_drag(start: Vector2, movement: Vector2) -> void:
	_send_touch(start, true)
	await _frames()
	var previous: Vector2 = start
	for step in range(1, 13):
		var point: Vector2 = start + movement * float(step) / 12.0
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = _tree.root.get_final_transform() * point
		event.relative = _tree.root.get_final_transform().basis_xform(point - previous)
		event.velocity = event.relative * 60.0
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _tree.process_frame
		previous = point
	_send_touch(start + movement, false)
	await _frames()


func _send_touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = _tree.root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _check_targets_and_width(main: Node, page_name: String) -> void:
	var targets_fit: bool = true
	for button in main.find_children("*", "BaseButton", true, false):
		if button.is_visible_in_tree() and (button.size.x < 48 or button.size.y < 48):
			targets_fit = false
			print("Small touch target: %s %s" % [button.get_path(), button.size])
	_expect(targets_fit, "%s buttons have at least 48 logical pixels on both sides" % page_name)
	var scroll: ScrollContainer = main.find_child("PageScroll", true, false) as ScrollContainer
	var body: Control = main.find_child("PageBody", true, false) as Control
	var screen: Control = main.get("current_screen") as Control
	var viewport_bounds := Rect2(Vector2.ZERO, Vector2(_tree.root.size))
	_expect(scroll != null and body != null and _fits_width(body, scroll.get_global_rect()) and _fits_width(screen, viewport_bounds),
		"%s has no horizontal content overflow" % page_name)


func _fits_width(node: Node, bounds: Rect2) -> bool:
	if node is Control and node.is_visible_in_tree():
		var rectangle: Rect2 = node.get_global_rect()
		if rectangle.position.x < bounds.position.x - 1 or rectangle.end.x > bounds.end.x + 1:
			return false
	for child in node.get_children():
		if not _fits_width(child, bounds):
			return false
	return true


func _test_process_restart() -> void:
	var path := "user://pc_builder_process_test_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	var project_path: String = ProjectSettings.globalize_path("res://")
	var results: Array[Dictionary] = []
	for mode in ["write", "read"]:
		var output: Array = []
		# Bound a child runtime as well as checking its output, so a script error
		# cannot leave the parent waiting forever for a broken child process.
		var arguments: PackedStringArray = ["--headless", "--path", project_path, "--quit-after", "600", "--script", "res://tests/save_process_probe.gd", "--", mode, path]
		var code := OS.execute(OS.get_executable_path(), arguments, output, true)
		_expect(code == 0, "The isolated save %s process exits successfully" % mode)
		var result: Dictionary = {}
		for block in output:
			for line in str(block).split("\n"):
				if line.begins_with("PROCESS_SAVE_RESULT:"):
					var parsed: Variant = JSON.parse_string(line.trim_prefix("PROCESS_SAVE_RESULT:"))
					if parsed is Dictionary:
						result = parsed
		if code != 0 or result.is_empty():
			for block in output:
				print(block)
		results.append(result)
	_expect(not results[0].is_empty() and not results[1].is_empty() and results[0].get("pid") != results[1].get("pid") and results[1].get("pid") != OS.get_process_id(),
		"Writing and resuming progress occur in separate Godot processes")
	var resumed: Dictionary = results[1]
	_expect(resumed.get("before_coins") == 0 and resumed.get("coins") == 13000 and resumed.get("xp") == 300 and resumed.get("level") == 3 and resumed.get("gems") == 52 and resumed.get("current_job_id") == "esports" and resumed.get("completed_jobs") == ["study", "gaming"],
		"A fresh process resumes the two saved customer rewards and next esports job")
	for own_path in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(own_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(own_path))


func _frames() -> void:
	await _tree.process_frame
	await _tree.process_frame


func _expect(condition: bool, message: String) -> void:
	_report.call(condition, message)
