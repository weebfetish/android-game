extends Node
## Tint the drawing only: the native button and its touch target never scale.

var _button: BaseButton
var _tween: Tween


func _ready() -> void:
	_button = get_parent() as BaseButton
	_button.button_down.connect(_press)
	_button.button_up.connect(_release)
	_button.mouse_exited.connect(_release)
	_button.pressed.connect(_click)


func _press() -> void:
	if _button.disabled:
		return
	_stop_tween()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_button, "self_modulate", Color(0.86, 0.96, 0.92), 0.04)
	# Return automatically even if the press is cancelled or the button locks.
	_tween.tween_property(_button, "self_modulate", Color.WHITE, 0.10)


func _release() -> void:
	if _tween == null or not _tween.is_running():
		return
	_stop_tween()
	_tween = create_tween()
	_tween.tween_property(_button, "self_modulate", Color.WHITE, 0.08)


func _click() -> void:
	if not _button.disabled:
		# This helper also compiles while GameState loads its formatting helpers.
		# Look up optional audio at click time, after autoload startup finishes.
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.play_ui_click()


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
