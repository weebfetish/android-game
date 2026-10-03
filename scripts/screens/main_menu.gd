extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 0, "PC BUILDER LAB", "Build a study PC",
		"Choose the parts. Check your build. Learn as you go."
	)
	var job := ScreenUI.card(body, "Your first customer")
	job.add_child(ScreenUI.badge("STUDY PC", ScreenUI.BLUE))
	job.add_child(ScreenUI.label("%s needs a basic study PC." % GameState.customer_name, 24))
	job.add_child(ScreenUI.label("%s coins" % ScreenUI.money(GameState.customer_budget), 32, ScreenUI.ACCENT))
	job.add_child(ScreenUI.label("Customer budget", 18, ScreenUI.MUTED))

	var how_to := ScreenUI.card(body, "Three simple steps")
	how_to.add_child(ScreenUI.label("1. Choose five components.", 20))
	how_to.add_child(ScreenUI.label("2. Match parts and stay on budget.", 20))
	how_to.add_child(ScreenUI.label("3. Build the PC and earn a reward.", 20))

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
	GameState.start_new_request()
	navigate.emit("customer_request")


func _quit() -> void:
	get_tree().quit()
