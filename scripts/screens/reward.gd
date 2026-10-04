extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var was_claimed: bool = GameState.reward_claimed
	GameState.claim_reward()
	var has_reward: bool = GameState.reward_claimed
	var job: JobData = GameState.get_current_job()
	var title := "%s complete" % job.use_case if has_reward else "No reward yet"
	var subtitle := "A working build and a job well done." if has_reward else "Complete a successful build to collect the reward."
	var body := ScreenUI.create_page(self, 5, "REWARD", title, subtitle)
	if has_reward:
		var reward_card := ScreenUI.card(body, "Your reward")
		reward_card.add_child(ScreenUI.badge("JOB COMPLETE"))
		reward_card.add_child(ScreenUI.label("+%s coins" % ScreenUI.money(GameState.reward_coins), 32, ScreenUI.ACCENT))
		reward_card.add_child(ScreenUI.label("+%s XP" % ScreenUI.money(GameState.reward_xp), 26, ScreenUI.BLUE))
		reward_card.add_child(ScreenUI.label("+%d %s" % [GameState.last_reward_gems, "gem" if GameState.last_reward_gems == 1 else "gems"], 24, ScreenUI.WARNING))
		reward_card.add_child(ScreenUI.label("%s's %s is ready to use." % [job.name, job.use_case.to_lower().replace(" pc", " PC")], 20, ScreenUI.MUTED))
		if was_claimed:
			reward_card.add_child(ScreenUI.label("Already collected. Your totals have not increased again.", 18, ScreenUI.MUTED))
	var totals := ScreenUI.card(body, "Your progress")
	totals.add_child(ScreenUI.label("Level %d · %s XP" % [GameState.level, ScreenUI.money(GameState.xp)], 22, ScreenUI.BLUE))
	totals.add_child(ScreenUI.label("Coins: %s · Gems: %s" % [ScreenUI.money(GameState.coins), ScreenUI.money(GameState.gems)], 20))
	totals.add_child(ScreenUI.label("%d / %d customers completed" % [GameState.completed_jobs.size(), JobsCatalog.get_jobs().size()], 20))
	if GameState.save_error.is_empty():
		totals.add_child(ScreenUI.label("Progress saved on this device.", 18, ScreenUI.MUTED))
	else:
		totals.add_child(ScreenUI.label("Progress could not be saved: %s" % GameState.save_error, 18, ScreenUI.DANGER))
	var next: JobData = GameState.next_job()
	if next != null:
		totals.add_child(ScreenUI.label("Next: %s · %s" % [next.name, next.use_case], 20, ScreenUI.ACCENT))
	else:
		totals.add_child(ScreenUI.label("All available jobs are complete. Choose a customer to practise again.", 18, ScreenUI.MUTED))

	var actions := ScreenUI.actions(body)
	var replay_button := ScreenUI.button("Next customer" if next != null else "Build another PC", true)
	replay_button.name = "ReplayButton"
	replay_button.pressed.connect(_replay)
	actions.add_child(replay_button)
	var menu_button := ScreenUI.button("Main menu")
	menu_button.name = "MenuButton"
	menu_button.pressed.connect(_open_menu)
	actions.add_child(menu_button)


func _replay() -> void:
	if GameState.start_next_job():
		navigate.emit("customer_request")


func _open_menu() -> void:
	navigate.emit("main_menu")
