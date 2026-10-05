extends SceneTree
## Run separately for native touch checks, with or without --headless.

const AndroidChecks = preload("res://tests/android_input_tests.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var state: Node = root.get_node("GameState")
	state.save_path = "user://pc_builder_android_probe_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	state.save_enabled = false
	var checks := AndroidChecks.new()
	await checks.run(self, state, _check)
	print("Android readiness probes: %d checks, %d failures." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("TEST FAILED: " + message)
