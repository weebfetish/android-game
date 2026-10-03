class_name PlayerHUD
extends HBoxContainer
## Presentation only: refresh the current session balances when state changes.

var _coins: Label
var _xp: Label
var _state: Node


func _ready() -> void:
	name = "PlayerHUD"
	add_theme_constant_override("separation", 8)
	_coins = _counter("COINS", Color("ffd17c"), "CoinsValue")
	_xp = _counter("XP", Color("7fafff"), "XPValue")
	_state = get_node("/root/GameState")
	_refresh()
	_state.state_changed.connect(_refresh)


func _counter(title: String, color: Color, value_name: String) -> Label:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "HUDPanel"
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	panel.add_child(content)
	var caption := Label.new()
	caption.text = title
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", color)
	content.add_child(caption)
	var value := Label.new()
	value.name = value_name
	value.add_theme_font_size_override("font_size", 20)
	content.add_child(value)
	return value


func _refresh() -> void:
	_coins.text = ScreenUI.money(_state.coins)
	_xp.text = ScreenUI.money(_state.xp)
