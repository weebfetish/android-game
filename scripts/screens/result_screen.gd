extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var result: Dictionary = GameState.last_result
	var success: bool = result.get("success", false)
	var body := ScreenUI.create_page(
		self, 4, "RESULT", "SUCCESS" if success else "FAILURE",
		"The study PC meets every requirement." if success else "The PC needs a few changes. Read the reasons below and edit your parts."
	)
	if result.is_empty():
		body.add_child(ScreenUI.label("No build has been checked yet. Choose your parts and press Build PC.", 18))
	else:
		var overview := ScreenUI.card(body, "Build totals")
		overview.add_child(ScreenUI.label("Cost: %s / %s coins" % [ScreenUI.money(result["total_cost"]), ScreenUI.money(result["budget"])], 20))
		overview.add_child(ScreenUI.label("Power needed: %d W · PSU capacity: %d W" % [result["required_power"], result["psu_wattage"]], 18))
		if not success:
			var reasons_card := ScreenUI.card(body, "What to fix")
			for reason in result.get("reasons", PackedStringArray()):
				reasons_card.add_child(ScreenUI.label("• %s" % reason, 18, Color("ffb1b1")))
			if result.get("reasons", PackedStringArray()).is_empty():
				reasons_card.add_child(ScreenUI.label("Complete all five part selections before building.", 18))
		var checks_card := ScreenUI.card(body, "Compatibility checks")
		for check in result.get("checks", []):
			var passed: bool = check["passed"]
			var check_color := ScreenUI.accent_color() if passed else Color("ffb1b1")
			checks_card.add_child(ScreenUI.label("%s · %s" % ["PASS" if passed else "FAIL", check["title"]], 18, check_color))
			checks_card.add_child(ScreenUI.label(check["detail"], 16, ScreenUI.muted_color()))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
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
		body.add_child(ScreenUI.label("No coins or XP are awarded for a failed build.", 16, ScreenUI.muted_color()))


func _open_reward() -> void:
	navigate.emit("reward")


func _edit_parts() -> void:
	navigate.emit("parts_shop")
