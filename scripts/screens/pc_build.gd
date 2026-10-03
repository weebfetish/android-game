extends Control

signal navigate(screen_name: String)


func _ready() -> void:
	var body := ScreenUI.create_page(
		self, 3, "PC BUILD", "Ready for the workbench.",
		"Review your components, then check the finished PC."
	)
	var parts_card := ScreenUI.card(body, "Selected components")
	for category in PartsCatalog.CATEGORIES:
		_add_part_row(parts_card, category)

	var summary := ScreenUI.card(body, "Build summary")
	summary.add_child(ScreenUI.label("Total cost: %s / %s coins" % [ScreenUI.money(GameState.total_cost()), ScreenUI.money(GameState.customer_budget)], 24, ScreenUI.accent_color()))
	summary.add_child(ScreenUI.label("Estimated power needed: %d W" % BuildValidator.required_power(GameState.selected_parts), 20, ScreenUI.BLUE))
	var psu: PartData = GameState.selected_parts.get("psu")
	if psu != null:
		summary.add_child(ScreenUI.label("Selected PSU: %s | %s" % [psu.display_name, PartsCatalog.describe_part(psu)], 18))
	else:
		summary.add_child(ScreenUI.label("Selected PSU: no part selected", 18, ScreenUI.WARNING))
	summary.add_child(ScreenUI.label("The provided case and cooling add a fixed 30 W and cost no coins.", 18, ScreenUI.muted_color()))
	if not GameState.has_all_parts():
		summary.add_child(ScreenUI.label("Choose all five components before building.", 18, ScreenUI.WARNING))

	# The action bar stays visible while the component list scrolls.
	var actions := ScreenUI.actions(body)
	var build_button := ScreenUI.button("Build PC", true)
	build_button.name = "BuildButton"
	build_button.disabled = not GameState.has_all_parts()
	build_button.pressed.connect(_build_pc)
	actions.add_child(build_button)
	var edit_button := ScreenUI.button("Edit parts")
	edit_button.name = "EditPartsButton"
	edit_button.pressed.connect(_edit_parts)
	actions.add_child(edit_button)


func _add_part_row(parent: VBoxContainer, category: String) -> void:
	var part: PartData = GameState.selected_parts.get(category)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var badge_text := "MB" if category == "motherboard" else PartsCatalog.category_label(category)
	row.add_child(ScreenUI.badge(badge_text, ScreenUI.BLUE))
	if part == null:
		var empty_label := ScreenUI.label("%s: no part selected" % PartsCatalog.category_label(category), 20, ScreenUI.WARNING)
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(empty_label)
	else:
		var name_label := ScreenUI.label(part.display_name, 20)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var price_label := ScreenUI.label("%s coins" % ScreenUI.money(part.price), 18)
		price_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(price_label)
		parent.add_child(ScreenUI.label(PartsCatalog.describe_part(part), 18, ScreenUI.muted_color()))
	# Separators belong to the component card, including for empty slots.
	if category != PartsCatalog.CATEGORIES[-1]:
		parent.add_child(HSeparator.new())


func _build_pc() -> void:
	if GameState.has_all_parts():
		GameState.evaluate_build()
		navigate.emit("result_screen")


func _edit_parts() -> void:
	navigate.emit("parts_shop")
