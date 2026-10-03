class_name ScreenUI
extends RefCounted
## Shared, lightweight layout helpers. All game rules remain in GameState.

const DEFAULT_THEME: Theme = preload("res://theme/default_theme.tres")
const BACKGROUND: Color = Color("101724")
const TEXT: Color = Color("f1f5fb")
const MUTED: Color = Color("a1afc6")
const ACCENT: Color = Color("62e3b8")
const BLUE: Color = Color("7fafff")
const WARNING: Color = Color("ffd17c")
const DANGER: Color = Color("ff8e9a")
const COMPACT_WIDTH: float = 760.0


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
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)
	_update_margins(root, margin)
	root.resized.connect(_update_margins.bind(root, margin))

	var page := VBoxContainer.new()
	page.name = "PageLayout"
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	page.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", 2)
	header.add_child(brand)
	var brand_name := label("PC LAB", 22, TEXT)
	brand_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.add_child(brand_name)
	var tagline := label("BUILD / LEARN", 11, ACCENT)
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.add_child(tagline)
	header.add_child(PlayerHUD.new())

	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation", 8)
	page.add_child(progress)
	for index in range(1, 6):
		var bar := ColorRect.new()
		bar.custom_minimum_size.y = 4
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.color = ACCENT if index <= step else Color("29374c")
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.add_child(bar)

	# Only content scrolls; currency and action buttons stay on screen.
	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	page.add_child(scroll)
	var body := VBoxContainer.new()
	body.name = "PageBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	body.set_meta("page_root", root)
	body.set_meta("page_layout", page)
	body.set_meta("page_scroll", scroll)

	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	body.add_child(heading)
	var step_text := eyebrow.to_upper()
	if step > 0:
		step_text = "%s  /  %02d OF 05" % [step_text, step]
	heading.add_child(label(step_text, 13, ACCENT))
	var title_label := label(title, 32, TEXT)
	heading.add_child(title_label)
	_update_title(root, title_label)
	root.resized.connect(_update_title.bind(root, title_label))
	if not subtitle.is_empty():
		heading.add_child(label(subtitle, 18, MUTED))
	return body


static func is_compact(root: Control) -> bool:
	return root.size.x < COMPACT_WIDTH


static func _update_margins(root: Control, margin: MarginContainer) -> void:
	var side: int = 18 if is_compact(root) else maxi(28, int((root.size.x - 1120) / 2))
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)


static func _update_title(root: Control, title_label: Label) -> void:
	title_label.add_theme_font_size_override("font_size", 30 if is_compact(root) else 36)


static func actions(body: VBoxContainer) -> BoxContainer:
	var root: Control = body.get_meta("page_root")
	var page: VBoxContainer = body.get_meta("page_layout")
	var footer := PanelContainer.new()
	footer.name = "ActionFooter"
	footer.theme_type_variation = "FooterPanel"
	page.add_child(footer)
	var row := BoxContainer.new()
	row.name = "PageActions"
	row.add_theme_constant_override("separation", 10)
	footer.add_child(row)
	_update_actions(root, row)
	root.resized.connect(_update_actions.bind(root, row))
	return row


static func _update_actions(root: Control, row: BoxContainer) -> void:
	row.vertical = is_compact(root)


static func sticky_card(body: VBoxContainer, title: String = "") -> VBoxContainer:
	var page: VBoxContainer = body.get_meta("page_layout")
	var scroll: ScrollContainer = body.get_meta("page_scroll")
	var content := card(page, title)
	page.move_child(content.get_parent(), scroll.get_index())
	return content


static func responsive_grid(root: Control, parent: Node) -> GridContainer:
	var grid := GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)
	_update_grid(root, grid)
	# Each grid needs its own callback when a page has several categories.
	root.resized.connect(func() -> void: _update_grid(root, grid))
	return grid


static func _update_grid(root: Control, grid: GridContainer) -> void:
	grid.columns = 1 if is_compact(root) else 2


static func label(text: String, font_size: int = 20, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


static func card(parent: Node, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	if not title.is_empty():
		content.add_child(label(title, 21, TEXT))
	return content


static func section(parent: Node, title: String, kicker: String = "") -> VBoxContainer:
	var content := card(parent, title)
	if not kicker.is_empty():
		content.add_child(label(kicker, 16, MUTED))
	return content


static func badge(text: String, color: Color = ACCENT) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.12)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var text_label := label(text, 13, color)
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(text_label)
	return panel


static func button(text: String, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 60
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		result.theme_type_variation = "PrimaryButton"
	return result


static func money(amount: int) -> String:
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
