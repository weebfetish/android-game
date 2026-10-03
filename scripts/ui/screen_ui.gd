class_name ScreenUI
extends RefCounted
## Small shared helpers for placeholder UI. Gameplay stays in screen scripts.

const DEFAULT_THEME: Theme = preload("res://theme/default_theme.tres")
const BACKGROUND: Color = Color("0c111a")
const TEXT: Color = Color("eef4fa")
const MUTED: Color = Color("a3b4c7")
const ACCENT: Color = Color("68dec5")
const STEPS: PackedStringArray = ["Menu", "Request", "Shop", "Build", "Result", "Reward"]


static func create_page(
	root: Control, step: int, eyebrow: String, title: String, subtitle: String
) -> VBoxContainer:
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = DEFAULT_THEME

	var background := ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)

	var brand_row := HBoxContainer.new()
	page.add_child(brand_row)
	var brand := label("PC / BUILDER", 20, ACCENT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_row.add_child(brand)
	var edition := label("PROTOTYPE 01", 13, MUTED)
	# A compact, non-wrapping label keeps the header at one line.
	edition.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand_row.add_child(edition)

	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation", 12)
	page.add_child(progress)
	for index in range(STEPS.size()):
		var text := "%02d  %s" % [index + 1, STEPS[index]]
		var step_label := label(text, 14, ACCENT if index == step else MUTED)
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.add_child(step_label)

	page.add_child(HSeparator.new())
	page.add_child(label(eyebrow.to_upper(), 13, ACCENT))
	page.add_child(label(title, 32, TEXT))
	if not subtitle.is_empty():
		page.add_child(label(subtitle, 17, MUTED))

	# Every page can scroll if the player uses a smaller window.
	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var body := VBoxContainer.new()
	body.name = "PageBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	return body


static func label(text: String, font_size: int = 18, color: Color = Color.WHITE) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


static func card(parent: Node, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	if not title.is_empty():
		content.add_child(label(title, 19, TEXT))
	return content


static func button(text: String, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 46
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		result.theme_type_variation = "PrimaryButton"
	return result


static func money(amount: int) -> String:
	# Group digits without a plugin or locale dependency.
	var digits := str(absi(amount))
	var formatted := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += ","
		formatted += digits[index]
	return ("-" if amount < 0 else "") + formatted


static func muted_color() -> Color:
	return MUTED


static func accent_color() -> Color:
	return ACCENT
