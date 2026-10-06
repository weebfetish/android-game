class_name UiMotion
extends RefCounted
## Short, one-shot presentation tweens. No motion changes game state.

const ButtonFeedback = preload("res://scripts/ui/button_feedback.gd")


static func enter_screen(target: Control) -> Tween:
	# The page stays in place and accepts input throughout this short fade.
	target.modulate.a = 0.72
	var tween := target.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)
	return tween


static func bind_button_feedback(button: BaseButton) -> void:
	var feedback := ButtonFeedback.new()
	feedback.name = "ButtonFeedback"
	button.add_child(feedback)


static func fade_in(target: Control, duration: float = 0.18) -> Tween:
	target.modulate.a = 0.0
	var tween := target.create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)
	return tween


static func fade_slide(target: Control, distance: float = 6.0, duration: float = 0.22) -> Tween:
	# Use inside a plain Control frame so containers still own page layout.
	var resting_position := target.position
	target.position.y += distance
	target.modulate.a = 0.0
	var tween := target.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", resting_position, duration)
	tween.tween_property(target, "modulate:a", 1.0, duration)
	return tween


static func pop(target: Control) -> Tween:
	target.scale = Vector2.ONE
	var tween := target.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2.ONE * 1.06, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN_OUT)
	return tween


static func pulse(target: Control) -> Tween:
	# Only a decorative status or badge scales, never an interactive control.
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	var tween := target.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2.ONE * 1.035, 0.07).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.13).set_ease(Tween.EASE_IN_OUT)
	return tween


static func shake(target: Control) -> Tween:
	# A tiny tilt avoids fighting container positions or moving explanations.
	target.pivot_offset = target.size * 0.5
	target.rotation = 0.0
	var tween := target.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "rotation", 0.006, 0.04)
	tween.tween_property(target, "rotation", -0.006, 0.05)
	tween.tween_property(target, "rotation", 0.003, 0.04)
	tween.tween_property(target, "rotation", 0.0, 0.05)
	return tween


static func count_label(
	target: Label, amount: int, suffix: String, duration: float = 0.45, prefix: String = "+"
) -> Tween:
	# This counter writes text only. The reward has already been awarded/saved.
	var update := func(value: float) -> void:
		target.text = "%s%s%s" % [prefix, ScreenUI.money(roundi(value)), suffix]
	update.call(0.0)
	var tween := target.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(update, 0.0, float(amount), duration)
	tween.tween_callback(update.bind(float(amount)))
	return tween
