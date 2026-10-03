extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var was_claimed: bool = GameState.reward_claimed
	GameState.claim_reward()
	var has_reward: bool = GameState.reward_claimed
	var title := "Job complete." if has_reward else "No reward available yet."
	var subtitle := "Your successful build earned coins and XP." if has_reward else "Complete a successful build to collect the job reward."
	var body := ScreenUI.create_page(self, 5, "REWARD", title, subtitle)
	if has_reward:
		var reward_card := ScreenUI.card(body, "Reward received")
		reward_card.add_child(ScreenUI.label("+%s coins" % ScreenUI.money(GameState.reward_coins), 30, ScreenUI.accent_color()))
		reward_card.add_child(ScreenUI.label("+%s XP" % ScreenUI.money(GameState.reward_xp), 26))
		reward_card.add_child(ScreenUI.label("Mika's study PC is ready to use.", 18, ScreenUI.muted_color()))
		if was_claimed:
			reward_card.add_child(ScreenUI.label("This job's reward was already collected. Your totals have not increased again.", 16, ScreenUI.muted_color()))
	var totals := ScreenUI.card(body, "Your progress this session")
	totals.add_child(ScreenUI.label("Coins: %s" % ScreenUI.money(GameState.coins), 22))
	totals.add_child(ScreenUI.label("XP: %s" % ScreenUI.money(GameState.xp), 22))
	totals.add_child(ScreenUI.label("You can repeat the same study PC job to practise. Progress resets when you close the game.", 16, ScreenUI.muted_color()))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	var replay_button := ScreenUI.button("Build another study PC", true)
	replay_button.name = "ReplayButton"
	replay_button.pressed.connect(_replay)
	actions.add_child(replay_button)
	var menu_button := ScreenUI.button("Main menu")
	menu_button.name = "MenuButton"
	menu_button.pressed.connect(_open_menu)
	actions.add_child(menu_button)


func _replay() -> void:
	GameState.start_new_request()
	navigate.emit("customer_request")


func _open_menu() -> void:
	navigate.emit("main_menu")
