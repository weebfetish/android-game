extends Control

signal navigate(screen_name: String)

const ChoiceCard = preload("res://scripts/ui/part_choice_card.gd")

var _option_buttons: Dictionary = {}
var _lock_labels: Dictionary = {}
var _total_label: Label
var _selection_label: Label
var _power_label: Label
var _status_label: Label
var _continue_button: Button


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 2, "PARTS SHOP", "Choose your components.",
		"Select one part in each category. Tap a selected part again to remove it."
	)
	var summary := ScreenUI.sticky_card(body)
	summary.add_theme_constant_override("separation", 4)
	_total_label = ScreenUI.label("", 20, ScreenUI.ACCENT)
	summary.add_child(_total_label)
	_selection_label = ScreenUI.label("", 18)
	summary.add_child(_selection_label)
	_power_label = ScreenUI.label("", 16, ScreenUI.MUTED)
	summary.add_child(_power_label)

	for category in PartsCatalog.CATEGORIES:
		_add_category(body, category)

	_status_label = ScreenUI.label("", 18, ScreenUI.MUTED)
	body.add_child(_status_label)
	var actions := ScreenUI.actions(body)
	_continue_button = ScreenUI.button("Review PC build", true)
	_continue_button.name = "ContinueButton"
	_continue_button.pressed.connect(_open_build)
	actions.add_child(_continue_button)
	var back_button := ScreenUI.button("Back to request")
	back_button.name = "BackButton"
	back_button.pressed.connect(_open_request)
	actions.add_child(back_button)
	GameState.state_changed.connect(_refresh_summary)
	_refresh_summary()


func _add_category(parent: Node, category: String) -> void:
	var card := ScreenUI.card(parent, PartsCatalog.category_label(category))
	var choices := ScreenUI.responsive_grid(self, card)
	for part in PartsCatalog.get_parts(category):
		var option := VBoxContainer.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_constant_override("separation", 6)
		choices.add_child(option)
		var choice := ChoiceCard.new(part)
		choice.pressed.connect(_select_part.bind(category, part))
		option.add_child(choice)
		_option_buttons[part.id] = choice
		var lock_label := ScreenUI.label("Unlocks at level %d" % part.unlock_level, 18, ScreenUI.WARNING)
		lock_label.name = "LockRequirement"
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option.add_child(lock_label)
		_lock_labels[part.id] = lock_label


func _select_part(category: String, part: PartData) -> void:
	var selected: PartData = GameState.selected_parts.get(category)
	if selected != null and selected.id == part.id:
		GameState.select_part(category, null)
	else:
		GameState.select_part(category, part)


func _refresh_summary() -> void:
	var total := GameState.total_cost()
	var remaining: int = GameState.customer_budget - total
	_total_label.text = "Total: %s / %s coins" % [ScreenUI.money(total), ScreenUI.money(GameState.customer_budget)]
	_selection_label.text = "%d / 5 selected · %s coins left" % [GameState.selected_parts.size(), ScreenUI.money(remaining)]
	_power_label.text = "Power: %d W · includes 30 W overhead" % BuildValidator.required_power(GameState.selected_parts)
	_total_label.add_theme_color_override("font_color", ScreenUI.DANGER if remaining < 0 else ScreenUI.ACCENT)
	_selection_label.add_theme_color_override("font_color", ScreenUI.DANGER if remaining < 0 else ScreenUI.TEXT)
	for category in PartsCatalog.CATEGORIES:
		var selected: PartData = GameState.selected_parts.get(category)
		for part in PartsCatalog.get_parts(category):
			var choice: PartChoiceCard = _option_buttons[part.id]
			choice.disabled = part.unlock_level > GameState.level
			var lock_label: Label = _lock_labels[part.id]
			lock_label.visible = choice.disabled
			choice.set_selected(selected != null and selected.id == part.id)
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
