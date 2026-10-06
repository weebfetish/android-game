extends RefCounted
## Presentation regression checks. All saves use the runner's isolated test path.

const SaveStore = preload("res://scripts/save_data.gd")
const Motion = preload("res://scripts/ui/ui_motion.gd")

var _tree: SceneTree
var _state: Node
var _report: Callable


func run(tree: SceneTree, state: Node, report: Callable) -> void:
	_tree = tree
	_state = state
	_report = report
	var old_size: Vector2i = tree.root.size
	var old_scale: Vector2i = tree.root.content_scale_size
	var old_save_enabled: bool = state.save_enabled
	for viewport_size in [Vector2i(360, 800), Vector2i(440, 900)]:
		state.save_enabled = false
		state.reset_progress()
		tree.root.content_scale_size = viewport_size
		tree.root.size = viewport_size
		var main: Node = load("res://scenes/main.tscn").instantiate()
		tree.root.add_child(main)
		await _frames()
		var profile: String = "%d x %d" % [viewport_size.x, viewport_size.y]
		await _test_navigation(main, profile)
		await _test_buttons_and_cards(main, profile)
		await _test_results(main, profile)
		await _test_reward(main, profile, viewport_size.x == 440)
		main.queue_free()
		await _frames()
	await _test_audio()
	await _test_status_feedback()
	state.save_enabled = old_save_enabled
	state.reset_progress()
	tree.root.size = old_size
	tree.root.content_scale_size = old_scale
	await _frames()


func _test_navigation(main: Node, profile: String) -> void:
	var before := _progress()
	for screen_name in ["customer_request", "parts_shop", "pc_build", "main_menu"]:
		# The transition starts as soon as the normal deferred navigation runs.
		main.current_screen.emit_signal("navigate", screen_name)
		await _frames()
		_expect(main.current_screen_name == screen_name,
			"%s navigation does not wait for a presentation tween at %s" % [screen_name, profile])
		var screen: Control = main.current_screen
		_expect(not screen.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"%s screen stays available to input during its entrance at %s" % [screen_name, profile])
		await _settle(0.28)
		_expect(screen.modulate.a > 0.999 and screen.scale.is_equal_approx(Vector2.ONE)
			and screen.position.is_equal_approx(Vector2.ZERO),
			"%s entrance settles with no root transform drift at %s" % [screen_name, profile])
		_check_buttons(screen, profile + " " + screen_name)
	_expect(_progress() == before, "Screen transitions do not mutate progression at %s" % profile)


func _test_buttons_and_cards(main: Node, profile: String) -> void:
	main._show_screen("parts_shop")
	await _frames()
	var before := _progress()
	var back: Button = main.find_child("BackButton", true, false)
	var card: Button = main.find_child("cpu_s4", true, false)
	var locked: Button
	_expect(back != null and card != null, "Button and card feedback targets exist at %s" % profile)
	if back == null or card == null:
		return
	var original_rect: Rect2 = back.get_global_rect()
	back.button_down.emit()
	await _settle(0.09)
	_expect(back.get_global_rect().is_equal_approx(original_rect)
		and back.scale.is_equal_approx(Vector2.ONE),
		"Pressed button tint preserves its exact touch target at %s" % profile)
	back.button_up.emit()
	await _settle(0.18)
	_expect(back.self_modulate.is_equal_approx(Color.WHITE)
		and back.get_global_rect().is_equal_approx(original_rect),
		"Released button feedback returns to its original color and bounds at %s" % profile)
	_expect(_progress() == before, "Button-down feedback cannot change the wallet or job at %s" % profile)
	var original_card_rect: Rect2 = card.get_global_rect()
	# Rapid real pressed signals exercise both selection and cancellation of the pop.
	card.pressed.emit()
	card.pressed.emit()
	card.pressed.emit()
	card.pressed.emit()
	await _settle(0.28)
	var icon: TextureRect = card.find_child("PartIcon", true, false)
	_expect(icon != null and icon.scale.is_equal_approx(Vector2.ONE),
		"Rapid part selection/deselection leaves the icon at its resting scale at %s" % profile)
	_expect(_state.selected_parts.is_empty() and not card.button_pressed,
		"Rapid part feedback leaves the correct deselected game state at %s" % profile)
	_expect(card.get_global_rect().is_equal_approx(original_card_rect)
		and card.scale.is_equal_approx(Vector2.ONE),
		"Part pop never changes card bounds or touch geometry at %s" % profile)
	_expect(_progress() == before, "Part feedback changes no economy or progression at %s" % profile)
	# Verify the normal catalog lock without relying on a specific part ID.
	if locked == null:
		for button in main.find_children("*", "Button", true, false):
			if button.has_meta("part_id") and button.disabled:
				locked = button
				break
	_expect(locked != null and locked.disabled
		and locked.get_theme_stylebox("disabled") != locked.get_theme_stylebox("normal"),
		"Locked choices retain a visibly distinct disabled style at %s" % profile)


func _test_results(main: Node, profile: String) -> void:
	_state.start_new_request()
	_state.evaluate_build()
	var failure: Dictionary = _state.last_result.duplicate(true)
	var before := _progress()
	main._show_screen("result_screen")
	await _frames()
	var status: Label = main.find_child("ResultStatus", true, false)
	_expect(status != null and status.text == "FAILURE", "Failure remains clearly labelled at %s" % profile)
	var explanations: Array[Label] = []
	var positions: Array[Vector2] = []
	for reason in failure.get("reasons", PackedStringArray()):
		var found := _find_label(main, reason)
		_expect(found != null, "The failure animation preserves the explanation '%s' at %s" % [reason, profile])
		if found != null:
			explanations.append(found)
			positions.append(found.position)
	await _settle(0.28)
	for index in explanations.size():
		_expect(explanations[index].position.is_equal_approx(positions[index])
			and explanations[index].scale.is_equal_approx(Vector2.ONE),
			"Failure shake does not move educational explanation %d at %s" % [index, profile])
	if status != null:
		_expect(status.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(status.rotation),
			"Failure status settles at its resting transform at %s" % profile)
	_expect(_state.last_result == failure and _progress() == before,
		"Failure presentation changes neither validation nor progression at %s" % profile)
	_check_buttons(main.current_screen, profile + " failure")
	_select_study_parts()
	_state.evaluate_build()
	var success: Dictionary = _state.last_result.duplicate(true)
	_expect(success.get("success", false), "The unchanged basic study build succeeds at %s" % profile)
	main._show_screen("result_screen")
	await _settle(0.28)
	status = main.find_child("ResultStatus", true, false)
	_expect(status != null and status.text == "SUCCESS" and status.scale.is_equal_approx(Vector2.ONE),
		"Success pulse finishes at its resting scale at %s" % profile)
	_expect(_state.last_result == success and _progress() == before,
		"Success presentation leaves validation and the unclaimed wallet unchanged at %s" % profile)
	_check_buttons(main.current_screen, profile + " success")


func _test_reward(main: Node, profile: String, leave_early: bool) -> void:
	_state.save_enabled = true
	main._show_screen("reward")
	# Reward settlement is synchronous; its numbers are only a visual count.
	var expected := _progress()
	_expect(_state.reward_claimed and _state.coins == 5000 and _state.xp == 100
		and _state.level == 2 and _state.gems == 51
		and _state.completed_jobs == PackedStringArray(["study"]),
		"The reward commits the original study progression before its animation at %s" % profile)
	var saved: Dictionary = SaveStore.read(_state.save_path)
	_expect(saved.get("ok", false) and saved["data"]["coins"] == 5000
		and saved["data"]["xp"] == 100 and saved["data"]["gems"] == 51
		and saved["data"]["level"] == 2 and saved["data"]["completed_jobs"] == ["study"],
		"Reward animation begins only after the isolated save contains the awarded totals at %s" % profile)
	var coins: Label = main.find_child("RewardCoins", true, false)
	var xp: Label = main.find_child("RewardXP", true, false)
	var gems: Label = main.find_child("RewardGems", true, false)
	_expect(coins != null and xp != null and gems != null, "All reward currencies have count labels at %s" % profile)
	if coins == null or xp == null or gems == null:
		_state.save_enabled = false
		return
	_expect(coins.text == "+0 coins" and xp.text == "+0 XP" and gems.text.begins_with("+0 "),
		"Fresh reward presentation starts its visual count at zero at %s" % profile)
	if leave_early:
		main._show_screen("main_menu")
		await _settle(0.55)
		_expect(_progress() == expected, "Leaving mid-count cannot cancel or duplicate a reward at %s" % profile)
	else:
		await _settle(0.12)
		var counted_coins: int = coins.text.trim_prefix("+").trim_suffix(" coins").replace(",", "").to_int()
		_expect(counted_coins > 0 and counted_coins < 5000,
			"The visual coin count advances through intermediate values at %s" % profile)
		await _settle(0.45)
		_expect(coins.text == "+5,000 coins" and xp.text == "+100 XP" and gems.text == "+1 gem",
			"The lightweight count finishes with the exact coin, XP and gem reward at %s" % profile)
		_expect(_progress() == expected, "Counting reward numbers never changes saved progression at %s" % profile)
		_check_buttons(main.current_screen, profile + " reward")
	main._show_screen("reward")
	coins = main.find_child("RewardCoins", true, false)
	xp = main.find_child("RewardXP", true, false)
	gems = main.find_child("RewardGems", true, false)
	_expect(coins != null and coins.text == "+5,000 coins" and xp.text == "+100 XP" and gems.text == "+1 gem",
		"Reopening an already collected reward displays settled numbers immediately at %s" % profile)
	await _settle(0.55)
	_expect(_progress() == expected, "Reopening reward presentation cannot claim the job a second time at %s" % profile)
	saved = SaveStore.read(_state.save_path)
	_expect(saved.get("ok", false) and saved["data"]["coins"] == 5000
		and saved["data"]["xp"] == 100 and saved["data"]["gems"] == 51,
		"Completed or cancelled counts preserve the on-disk reward totals at %s" % profile)
	_state.save_enabled = false


func _test_audio() -> void:
	var audio: Node = _tree.root.get_node_or_null("AudioManager")
	_expect(audio != null, "The optional AudioManager autoload is available")
	if audio == null:
		return
	var before := _progress()
	var original_children: Array[Node] = audio.get_children()
	var paths: Array[String] = [audio.MUSIC_PATH, audio.UI_CLICK_PATH, audio.PART_SELECT_PATH,
		audio.SUCCESS_PATH, audio.FAILURE_PATH, audio.REWARD_PATH]
	# Independent of future supplied assets: force a known absent optional stream.
	_expect(audio._load_optional_stream("res://assets/audio/sfx/__missing_test_sound.wav") == null,
		"A missing optional audio file is handled without ResourceLoader errors")
	for repetition in 12:
		audio.play_music()
		audio.play_ui_click()
		audio.play_part_select()
		audio.play_success()
		audio.play_failure()
		audio.play_reward()
		audio.stop_music()
	_expect(audio.get_children() == original_children and original_children.size() == 4,
		"Rapid audio requests reuse one music player and a bounded three-player SFX pool")
	_expect(audio._sfx_players.size() == 3, "Optional SFX cannot create an unbounded player pool")
	for path in paths:
		_expect(audio._stream_cache.has(path), "Optional audio lookup is cached for %s" % path)
	# Exercise real playback and lifecycle branches on a separate manager so the
	# live autoload and its optional asset cache are never modified by tests.
	var isolated: Node = load("res://scripts/audio_manager.gd").new()
	_tree.root.add_child(isolated)
	var silent_wave := AudioStreamWAV.new()
	silent_wave.format = AudioStreamWAV.FORMAT_8_BITS
	silent_wave.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(8000)
	samples.fill(128)
	silent_wave.data = samples
	for path in paths:
		isolated._stream_cache[path] = silent_wave
	var isolated_players: Array[Node] = isolated.get_children()
	isolated.play_music()
	for repetition in 12:
		isolated.play_ui_click()
		isolated.play_part_select()
		isolated.play_success()
		isolated.play_failure()
		isolated.play_reward()
	_expect(isolated._music_player.playing,
		"Supplying an optional stream starts music without new player nodes")
	_expect(isolated.get_children() == isolated_players and isolated._next_sfx_voice == 0,
		"Rapid playable sound effects rotate through the same fixed three voices")
	for player in isolated._sfx_players:
		_expect(player.playing, "Each reusable SFX voice can play a supplied stream")
	isolated.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_expect(isolated._backgrounded and isolated._music_player.stream_paused,
		"Application backgrounding pauses music playback")
	for player in isolated._sfx_players:
		_expect(not player.playing, "Application backgrounding stops transient sound effects")
	var voice_before: int = isolated._next_sfx_voice
	isolated.play_ui_click()
	_expect(isolated._next_sfx_voice == voice_before,
		"Backgrounded audio ignores UI playback requests")
	isolated.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_expect(not isolated._backgrounded and not isolated._music_player.stream_paused
		and isolated._music_player.playing,
		"Returning to the application resumes requested music")
	isolated.stop_music()
	_expect(not isolated._music_player.playing and not isolated._music_requested,
		"Explicit music stop clears its playback request")
	isolated.queue_free()
	await _frames()
	_expect(_progress() == before, "Optional music and all six audio hooks never mutate game data")


func _select_study_parts() -> void:
	for part_id in ["cpu_s4", "board_a", "ram_ddr4", "ssd_256", "psu_180"]:
		var part: PartData = PartsCatalog.find_part(part_id)
		_state.select_part(part.category, part)


func _test_status_feedback() -> void:
	# Manually advance decorative tweens to test their visible midpoint without
	# relying on this machine's frame timing or changing real screen buttons.
	var status := Label.new()
	status.text = "STATUS"
	status.size = Vector2(140, 40)
	_tree.root.add_child(status)
	var pulse: Tween = Motion.pulse(status)
	pulse.pause()
	pulse.custom_step(0.07)
	_expect(status.scale.x > 1.0 and status.scale.x < 1.08,
		"Positive status feedback has a small visible midpoint pulse")
	pulse.custom_step(1.0)
	_expect(status.scale.is_equal_approx(Vector2.ONE), "Positive status feedback restores its exact resting scale")
	var shake: Tween = Motion.shake(status)
	shake.pause()
	shake.custom_step(0.04)
	_expect(absf(status.rotation) > 0.0001 and absf(status.rotation) < 0.02,
		"Failure status feedback has a subtle visible midpoint shake")
	shake.custom_step(1.0)
	_expect(is_zero_approx(status.rotation), "Failure status feedback restores its exact resting rotation")
	status.queue_free()
	await _frames()


func _progress() -> Dictionary:
	return {"coins": _state.coins, "xp": _state.xp, "level": _state.level,
		"gems": _state.gems, "completed_jobs": _state.completed_jobs.duplicate(),
		"job": _state.current_job_id}


func _check_buttons(screen: Node, profile: String) -> void:
	for node in screen.find_children("*", "Button", true, false):
		var button: Button = node
		if button.is_visible_in_tree():
			_expect(button.size.x >= 48.0 and button.size.y >= 48.0,
				"Presentation keeps the %s touch target at least 48 logical pixels at %s" % [button.name, profile])
			_expect(button.scale.is_equal_approx(Vector2.ONE),
				"Presentation keeps the %s native button transform unchanged at %s" % [button.name, profile])


func _find_label(parent: Node, value: String) -> Label:
	for node in parent.find_children("*", "Label", true, false):
		if node.text == value:
			return node as Label
	return null


func _frames() -> void:
	for frame in 3:
		await _tree.process_frame


func _settle(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout
	await _frames()


func _expect(condition: bool, message: String) -> void:
	_report.call(condition, message)
