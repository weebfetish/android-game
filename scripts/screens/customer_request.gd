extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 1, "CUSTOMER REQUEST", "A desktop for studying",
		"Help Mika get a reliable first PC."
	)
	var request := ScreenUI.card(body, GameState.customer_name)
	request.add_child(ScreenUI.badge("STUDENT", ScreenUI.BLUE))
	request.add_child(ScreenUI.label(GameState.customer_request, 20))
	request.add_child(ScreenUI.label("Budget", 18, ScreenUI.MUTED))
	request.add_child(ScreenUI.label("%s coins" % ScreenUI.money(GameState.customer_budget), 32, ScreenUI.ACCENT))
	request.add_child(ScreenUI.label("Reward on success", 18, ScreenUI.MUTED))
	request.add_child(ScreenUI.label("+%s coins  ·  +%s XP" % [ScreenUI.money(GameState.reward_coins), ScreenUI.money(GameState.reward_xp)], 20, ScreenUI.WARNING))

	var requirements := ScreenUI.card(body, "Your build checklist")
	requirements.add_child(ScreenUI.label("CPU socket and RAM type match the motherboard.", 20))
	requirements.add_child(ScreenUI.label("The motherboard supports the SSD interface.", 20))
	requirements.add_child(ScreenUI.label("The PSU covers the whole PC's power demand.", 20))
	requirements.add_child(ScreenUI.label("All five parts stay within the budget.", 20))
	requirements.add_child(ScreenUI.label("Choose a CPU, motherboard, RAM, SSD and PSU. The provided case and cooling use 30 W.", 18, ScreenUI.MUTED))

	var actions := ScreenUI.actions(body)
	var accept_button := ScreenUI.button("Accept job", true)
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
