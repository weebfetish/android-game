extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 0, "PC BUILDER LAB", "Build your next PC",
		"Choose the parts. Check your build. Learn as you go."
	)
	if not GameState.save_error.is_empty():
		body.add_child(ScreenUI.label(GameState.save_error, 18, ScreenUI.DANGER))
	var next: JobData = GameState.next_job()
	if next == null:
		next = GameState.get_current_job()
	var job := ScreenUI.card(body, "Next customer")
	job.add_child(ScreenUI.badge(next.use_case.to_upper(), ScreenUI.BLUE))
	var use_case: String = next.use_case.to_lower().replace(" pc", " PC")
	var article: String = "an" if use_case.begins_with("esports") else "a"
	job.add_child(ScreenUI.label("%s needs %s %s." % [next.name, article, use_case], 24))
	job.add_child(ScreenUI.label("%s coins" % ScreenUI.money(next.budget), 32, ScreenUI.ACCENT))
	job.add_child(ScreenUI.label("Customer budget", 18, ScreenUI.MUTED))

	var how_to := ScreenUI.card(body, "Three simple steps")
	how_to.add_child(ScreenUI.label("1. Choose five components.", 20))
	how_to.add_child(ScreenUI.label("2. Match parts and stay on budget.", 20))
	how_to.add_child(ScreenUI.label("3. Build the PC and earn a reward.", 20))
	for customer in JobsCatalog.get_jobs():
		_add_job_card(body, customer)

	var actions := ScreenUI.actions(body)
	var start_button := ScreenUI.button("Start building", true)
	start_button.name = "StartButton"
	start_button.pressed.connect(_start_request)
	actions.add_child(start_button)
	var quit_button := ScreenUI.button("Quit")
	quit_button.name = "QuitButton"
	quit_button.pressed.connect(_quit)
	actions.add_child(quit_button)


func _start_request() -> void:
	if GameState.start_next_job():
		navigate.emit("customer_request")


func _add_job_card(parent: Node, job: JobData) -> void:
	var card := ScreenUI.card(parent, "%s · %s" % [job.name, job.use_case])
	var unlocked: bool = GameState.is_job_unlocked(job.id)
	if GameState.completed_jobs.has(job.id):
		card.add_child(ScreenUI.badge("COMPLETED"))
	elif not unlocked:
		card.add_child(ScreenUI.badge("LEVEL %d REQUIRED" % job.unlock_level, ScreenUI.MUTED))
	else:
		card.add_child(ScreenUI.badge("AVAILABLE", ScreenUI.BLUE))
	card.add_child(ScreenUI.label(job.personality, 18, ScreenUI.MUTED))
	card.add_child(ScreenUI.label("Budget: %s coins" % ScreenUI.money(job.budget), 22, ScreenUI.ACCENT))
	var choose_button := ScreenUI.button("Choose customer" if unlocked else "Unlocks at level %d" % job.unlock_level)
	choose_button.name = "Job_%s" % job.id
	choose_button.disabled = not unlocked
	choose_button.pressed.connect(_choose_job.bind(job.id))
	card.add_child(choose_button)


func _choose_job(job_id: String) -> void:
	if GameState.start_job(job_id):
		navigate.emit("customer_request")


func _quit() -> void:
	get_tree().quit()
