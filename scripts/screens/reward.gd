extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var was_claimed: bool = GameState.reward_claimed
	GameState.claim_reward()
	var has_reward: bool = GameState.reward_claimed
	var title := "Study PC complete" if has_reward else "No reward yet"
	var subtitle := "A working build and a job well done." if has_reward else "Complete a successful build to collect the reward."
	var body := ScreenUI.create_page(self, 5, "REWARD", title, subtitle)
	if has_reward:
		var reward_card := ScreenUI.card(body, "Your reward")
		reward_card.add_child(ScreenUI.badge("JOB COMPLETE"))
		reward_card.add_child(ScreenUI.label("+%s coins" % ScreenUI.money(GameState.reward_coins), 32, ScreenUI.ACCENT))
		reward_card.add_child(ScreenUI.label("+%s XP" % ScreenUI.money(GameState.reward_xp), 26, ScreenUI.BLUE))
		reward_card.add_child(ScreenUI.label("%s's study PC is ready to use." % GameState.customer_name, 20, ScreenUI.MUTED))
		if was_claimed:
			reward_card.add_child(ScreenUI.label("Already collected. Your totals have not increased again.", 18, ScreenUI.MUTED))
	var totals := ScreenUI.card(body, "Keep practising")
	totals.add_child(ScreenUI.label("Session coins: %s" % ScreenUI.money(GameState.coins), 20))
	totals.add_child(ScreenUI.label("Session XP: %s" % ScreenUI.money(GameState.xp), 20))
	totals.add_child(ScreenUI.label("Try the study PC job again. Your progress lasts until you close the game.", 18, ScreenUI.MUTED))

	var actions := ScreenUI.actions(body)
	var replay_button := ScreenUI.button("Build another PC", true)
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
