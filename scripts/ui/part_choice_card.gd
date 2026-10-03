class_name PartChoiceCard
extends Button
## A regular toggle button with readable, wrapping part information.

var _content: VBoxContainer
var _selection_text: Label
var _selection_badge: PanelContainer


func _init(part: PartData) -> void:
	name = part.id
	set_meta("part_id", part.id)
	set_meta("category", part.category)
	toggle_mode = true
	custom_minimum_size.y = 174
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = PartsCatalog.describe_part(part)
	add_theme_stylebox_override("normal", _card_style(Color("121e2d"), Color("31435a")))
	add_theme_stylebox_override("hover", _card_style(Color("1a2b3e"), ScreenUI.ACCENT))
	add_theme_stylebox_override("pressed", _card_style(Color("173b36"), ScreenUI.ACCENT, 2))
	add_theme_stylebox_override("hover_pressed", _card_style(Color("204a42"), ScreenUI.ACCENT, 2))
	add_theme_stylebox_override("focus", _card_style(Color.TRANSPARENT, ScreenUI.BLUE, 2))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	margin.add_child(_content)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	_content.add_child(heading)
	var tile := ScreenUI.badge(_component_code(part.category), ScreenUI.BLUE)
	tile.custom_minimum_size = Vector2(48, 48)
	tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	heading.add_child(tile)
	var name_and_price := VBoxContainer.new()
	name_and_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_and_price.add_theme_constant_override("separation", 4)
	heading.add_child(name_and_price)
	name_and_price.add_child(ScreenUI.label(part.display_name, 20, ScreenUI.TEXT))
	name_and_price.add_child(ScreenUI.label("%s coins" % ScreenUI.money(part.price), 22, ScreenUI.ACCENT))
	_content.add_child(ScreenUI.label(PartsCatalog.describe_part(part).replace(" | ", "  ·  "), 18, ScreenUI.MUTED))
	_selection_badge = ScreenUI.badge("TAP TO SELECT", ScreenUI.MUTED)
	_selection_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_content.add_child(_selection_badge)
	_selection_text = _selection_badge.get_child(0) as Label

	# Child labels decorate the button; the native button receives all input.
	_ignore_mouse_on_children(self)
	_content.minimum_size_changed.connect(_update_minimum_height)
	resized.connect(_update_minimum_height)
	toggled.connect(_update_selection_badge)
	_update_minimum_height()


func _update_minimum_height() -> void:
	# Wrapped specifications can need an extra line in a narrow window.
	var needed_height: float = maxf(174, _content.get_combined_minimum_size().y + 32)
	if not is_equal_approx(custom_minimum_size.y, needed_height):
		custom_minimum_size.y = needed_height


func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
	_update_selection_badge(selected)


func _update_selection_badge(selected: bool) -> void:
	_selection_text.text = "SELECTED" if selected else "TAP TO SELECT"
	_selection_text.add_theme_color_override("font_color", ScreenUI.ACCENT if selected else ScreenUI.MUTED)


func _ignore_mouse_on_children(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child)


func _component_code(category: String) -> String:
	return "MB" if category == "motherboard" else category.to_upper()


func _card_style(fill: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	return style
