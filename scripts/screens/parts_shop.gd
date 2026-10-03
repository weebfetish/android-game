extends Control

signal navigate(screen_name: String)

var _option_buttons: Dictionary = {}
var _total_label: Label
var _selection_label: Label
var _power_label: Label
var _status_label: Label
var _continue_button: Button


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 2, "PARTS SHOP", "Pick one of each component.",
		"Compare the price and specifications. Your selections stay selected while you edit the build."
	)
	var summary := ScreenUI.card(body, "Your basket")
	_total_label = ScreenUI.label("", 22, ScreenUI.accent_color())
	summary.add_child(_total_label)
	_selection_label = ScreenUI.label("", 18)
	summary.add_child(_selection_label)
	_power_label = ScreenUI.label("", 16, ScreenUI.muted_color())
	summary.add_child(_power_label)

	for category in PartsCatalog.CATEGORIES:
		_add_category(body, category)

	_status_label = ScreenUI.label("", 18, ScreenUI.muted_color())
	body.add_child(_status_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	_continue_button = ScreenUI.button("Continue to PC build", true)
	_continue_button.name = "ContinueButton"
	_continue_button.pressed.connect(_open_build)
	actions.add_child(_continue_button)
	var back_button := ScreenUI.button("Back to request")
	back_button.name = "BackButton"
	back_button.pressed.connect(_open_request)
	actions.add_child(back_button)
	_refresh_summary()


func _add_category(parent: Node, category: String) -> void:
	var card := ScreenUI.card(parent, PartsCatalog.category_label(category))
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	card.add_child(choices)
	for part in PartsCatalog.get_parts(category):
		# Break the longer motherboard specifications into two readable lines.
		var specifications := PartsCatalog.describe_part(part).replace(" | Storage: ", "\nStorage: ")
		var choice := ScreenUI.button("%s · %s coins\n%s" % [part.display_name, ScreenUI.money(part.price), specifications])
		choice.name = part.id
		choice.set_meta("part_id", part.id)
		choice.set_meta("category", category)
		choice.toggle_mode = true
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size.y = 82
		choice.add_theme_font_size_override("font_size", 16)
		choice.tooltip_text = PartsCatalog.describe_part(part)
		choice.pressed.connect(_select_part.bind(category, part))
		choices.add_child(choice)
		_option_buttons[part.id] = choice


func _select_part(category: String, part: PartData) -> void:
	GameState.select_part(category, part)
	_refresh_summary()


func _refresh_summary() -> void:
	var total := GameState.total_cost()
	var remaining: int = GameState.customer_budget - total
	_total_label.text = "Total: %s coins  /  Budget: %s coins" % [ScreenUI.money(total), ScreenUI.money(GameState.customer_budget)]
	_selection_label.text = "%d / 5 components selected · %s coins remaining" % [GameState.selected_parts.size(), ScreenUI.money(remaining)]
	_power_label.text = "Estimated power: %d W, including 30 W for the provided case and cooling." % BuildValidator.required_power(GameState.selected_parts)
	_selection_label.add_theme_color_override("font_color", Color("ffb1b1") if remaining < 0 else Color.WHITE)
	for category in PartsCatalog.CATEGORIES:
		var selected: PartData = GameState.selected_parts.get(category)
		for part in PartsCatalog.get_parts(category):
			var choice: Button = _option_buttons[part.id]
			choice.set_pressed_no_signal(selected != null and selected.id == part.id)
	_continue_button.disabled = not GameState.has_all_parts()
	if not GameState.has_all_parts():
		_status_label.text = "Choose all five components to continue."
	elif remaining < 0:
		_status_label.text = "This basket is over budget. You can review it on the build screen or choose cheaper parts."
	else:
		_status_label.text = "All five components are selected. Review the PC before you build it."


func _open_build() -> void:
	if GameState.has_all_parts():
		navigate.emit("pc_build")


func _open_request() -> void:
	navigate.emit("customer_request")
