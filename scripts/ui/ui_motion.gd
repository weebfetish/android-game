class_name UiMotion
extends RefCounted
## Short, one-shot presentation tweens. No motion changes game state.


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
