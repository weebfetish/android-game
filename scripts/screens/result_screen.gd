extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var result: Dictionary = GameState.last_result
	var success: bool = result.get("success", false)
	var body := ScreenUI.create_page(
		self, 4, "BUILD RESULT", "Compatibility report.",
		"See what passed and what needs attention."
	)
	if result.is_empty():
		body.add_child(ScreenUI.label("No build has been checked yet. Choose your parts and press Build PC.", 20))
	else:
		_add_status_banner(body, result, success)
		if not success:
			var reasons_card := ScreenUI.card(body, "What to fix")
			for reason in result.get("reasons", PackedStringArray()):
				reasons_card.add_child(ScreenUI.label(reason, 20, ScreenUI.DANGER))
			if result.get("reasons", PackedStringArray()).is_empty():
				reasons_card.add_child(ScreenUI.label("Complete all five part selections before building.", 20))

		var overview := ScreenUI.card(body, "Build totals")
		overview.add_child(ScreenUI.label("Cost: %s / %s coins" % [ScreenUI.money(result["total_cost"]), ScreenUI.money(result["budget"])], 22))
		overview.add_child(ScreenUI.label("Power needed: %d W | PSU capacity: %d W" % [result["required_power"], result["psu_wattage"]], 20, ScreenUI.BLUE))
		_add_checks(body, result.get("checks", []))
		if success:
			var reward_preview := ScreenUI.card(body, "Your reward is ready")
			reward_preview.add_child(ScreenUI.label("+%s coins  +%s XP" % [ScreenUI.money(GameState.reward_coins), ScreenUI.money(GameState.reward_xp)], 24, ScreenUI.accent_color()))
			var gems: int = 0 if GameState.completed_jobs.has(GameState.current_job_id) else GameState.reward_gems
			reward_preview.add_child(ScreenUI.label("+%d %s" % [gems, "gem" if gems == 1 else "gems"], 20, ScreenUI.WARNING))
			reward_preview.add_child(ScreenUI.label("Continue to collect your job reward.", 20, ScreenUI.muted_color()))
		else:
			body.add_child(ScreenUI.label("No coins or XP are awarded for a failed build.", 18, ScreenUI.muted_color()))

	var actions := ScreenUI.actions(body)
	if success:
		var reward_button := ScreenUI.button("Continue to reward", true)
		reward_button.name = "RewardButton"
		reward_button.pressed.connect(_open_reward)
		actions.add_child(reward_button)
	else:
		var edit_button := ScreenUI.button("Edit parts", true)
		edit_button.name = "EditPartsButton"
		edit_button.pressed.connect(_edit_parts)
		actions.add_child(edit_button)


func _add_status_banner(parent: Node, result: Dictionary, success: bool) -> void:
	var status_color := ScreenUI.accent_color() if success else ScreenUI.DANGER
	var banner := ScreenUI.card(parent, "")
	var style := StyleBoxFlat.new()
	style.bg_color = Color(status_color.r * 0.12, status_color.g * 0.12, status_color.b * 0.12, 1.0)
	style.border_color = status_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	var banner_panel: PanelContainer = banner.get_parent()
	banner_panel.name = "ResultBanner"
	banner_panel.add_theme_stylebox_override("panel", style)
	banner.add_child(ScreenUI.badge("BUILD VERIFIED" if success else "BUILD NEEDS CHANGES", status_color))
	banner.add_child(ScreenUI.label("SUCCESS" if success else "FAILURE", 32, status_color))
	if success:
		banner.add_child(ScreenUI.label("All checks passed.", 24))
		var job: JobData = GameState.get_current_job()
		banner.add_child(ScreenUI.label("%s's %s meets the request and stays within budget." % [job.name, job.use_case.to_lower().replace(" pc", " PC")], 20))
	else:
		var issue_count: int = result.get("reasons", PackedStringArray()).size()
		banner.add_child(ScreenUI.label("%d %s to fix." % [issue_count, "issue" if issue_count == 1 else "issues"], 24))
		banner.add_child(ScreenUI.label("Change the highlighted parts, then check your PC again.", 20))
	# A short fade marks the report without moving layout or delaying its buttons.
	UiMotion.fade_in(banner_panel)


func _add_checks(parent: Node, checks: Array) -> void:
	var card := ScreenUI.card(parent, "Compatibility checks")
	# Read failed checks first without sorting or editing the saved report.
	for passed in [false, true]:
		for check in checks:
			if check["passed"] != passed:
				continue
			var check_color := ScreenUI.accent_color() if passed else ScreenUI.DANGER
			var heading := HBoxContainer.new()
			heading.add_theme_constant_override("separation", 10)
			card.add_child(heading)
			heading.add_child(ScreenUI.badge("PASSED" if passed else "FAILED", check_color))
			var title := ScreenUI.label(check["title"], 20)
			title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			heading.add_child(title)
			card.add_child(ScreenUI.label(check["detail"], 18, ScreenUI.muted_color()))
			card.add_child(HSeparator.new())


func _open_reward() -> void:
	navigate.emit("reward")


func _edit_parts() -> void:
	navigate.emit("parts_shop")
