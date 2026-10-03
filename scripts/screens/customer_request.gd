extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 1, "CUSTOMER REQUEST", "A good start for a student.",
		"Read the job, then head to the shop to choose the parts."
	)
	var request := ScreenUI.card(body, "%s · student" % GameState.customer_name)
	request.add_child(ScreenUI.label(GameState.customer_request, 24))
	request.add_child(ScreenUI.label("Budget: %s coins" % ScreenUI.money(GameState.customer_budget), 22, ScreenUI.accent_color()))
	request.add_child(ScreenUI.label("Successful job reward: %s coins + %s XP" % [ScreenUI.money(GameState.reward_coins), ScreenUI.money(GameState.reward_xp)], 18))

	var requirements := ScreenUI.card(body, "What makes a successful build?")
	requirements.add_child(ScreenUI.label("1. The CPU socket matches the motherboard socket.", 18))
	requirements.add_child(ScreenUI.label("2. The RAM type matches the motherboard's RAM type.", 18))
	requirements.add_child(ScreenUI.label("3. The PSU supplies enough power for the whole PC.", 18))
	requirements.add_child(ScreenUI.label("4. All five parts cost no more than %s coins." % ScreenUI.money(GameState.customer_budget), 18))
	requirements.add_child(ScreenUI.label("Choose one CPU, motherboard, RAM kit, SSD and PSU. The case and cooling are provided and use 30 W.", 16, ScreenUI.muted_color()))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	var accept_button := ScreenUI.button("Accept job · open parts shop", true)
	accept_button.name = "AcceptButton"
	accept_button.pressed.connect(_open_shop)
	actions.add_child(accept_button)
	var menu_button := ScreenUI.button("Back to menu")
	menu_button.name = "MenuButton"
	menu_button.pressed.connect(_open_menu)
	actions.add_child(menu_button)


func _open_shop() -> void:
	navigate.emit("parts_shop")


func _open_menu() -> void:
	navigate.emit("main_menu")
