extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 0, "PC BUILDER LAB", "Build a study PC.",
		"A small, hands-on lesson in choosing compatible computer parts."
	)
	var job := ScreenUI.card(body, "Your first customer")
	job.add_child(ScreenUI.label("Mika needs a basic PC for studying.", 24))
	job.add_child(ScreenUI.label("Budget: %s coins" % ScreenUI.money(GameState.customer_budget), 20, ScreenUI.accent_color()))
	job.add_child(ScreenUI.label("Choose five components, check your build, then collect coins and XP.", 18, ScreenUI.muted_color()))

	var how_to := ScreenUI.card(body, "How it works")
	how_to.add_child(ScreenUI.label("Customer request  →  Parts shop  →  PC build  →  Result  →  Reward", 18))
	how_to.add_child(ScreenUI.label("Match the CPU socket and RAM type to the motherboard. Choose enough PSU power and stay within the customer's budget.", 18, ScreenUI.muted_color()))
	how_to.add_child(ScreenUI.label("This prototype uses placeholder parts and keeps progress in memory for this session.", 16, ScreenUI.muted_color()))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	var start_button := ScreenUI.button("Start customer request", true)
	start_button.name = "StartButton"
	start_button.pressed.connect(_start_request)
	actions.add_child(start_button)
	var quit_button := ScreenUI.button("Quit")
	quit_button.name = "QuitButton"
	quit_button.pressed.connect(_quit)
	actions.add_child(quit_button)


func _start_request() -> void:
	GameState.start_new_request()
	navigate.emit("customer_request")


func _quit() -> void:
	get_tree().quit()
