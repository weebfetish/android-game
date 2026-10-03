extends Control
## Owns screen navigation. Each screen emits navigate with one of these names.

const SCREENS: Dictionary = {
	"main_menu": preload("res://scenes/screens/main_menu.tscn"),
	"customer_request": preload("res://scenes/screens/customer_request.tscn"),
	"parts_shop": preload("res://scenes/screens/parts_shop.tscn"),
	"pc_build": preload("res://scenes/screens/pc_build.tscn"),
	"result_screen": preload("res://scenes/screens/result_screen.tscn"),
	"reward": preload("res://scenes/screens/reward.tscn"),
}

var current_screen: Control
var current_screen_name: String = ""
var _transition_queued: bool = false


func _ready() -> void:
	_show_screen("main_menu")


func _on_navigate(screen_name: String) -> void:
	# Wait until the button's signal finishes before removing its screen.
	# The guard also prevents a double click from creating two screens.
	if _transition_queued or not SCREENS.has(screen_name):
		return
	_transition_queued = true
	_show_screen.call_deferred(screen_name)


func _show_screen(screen_name: String) -> void:
	if is_instance_valid(current_screen):
		remove_child(current_screen)
		current_screen.queue_free()
	var scene: PackedScene = SCREENS[screen_name]
	current_screen = scene.instantiate() as Control
	current_screen_name = screen_name
	current_screen.connect("navigate", _on_navigate)
	add_child(current_screen)
	_transition_queued = false
