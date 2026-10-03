extends Node
## Autoloaded as GameState. The customer budget is separate from player rewards.

signal state_changed

var customer_name: String = "Mika"
var customer_request: String = "I need a basic study PC for homework, web browsing, and documents."
var customer_budget: int = 60000
var reward_coins: int = 5000
var reward_xp: int = 100
var coins: int = 0
var xp: int = 0
var selected_parts: Dictionary = {}
var last_result: Dictionary = {}
var reward_claimed: bool = false

# A snapshot prevents a result from rewarding a different build later.
var _evaluated_selection: Dictionary = {}
var _evaluated_budget: int = 0


func start_new_request() -> void:
	selected_parts.clear()
	last_result.clear()
	_evaluated_selection.clear()
	reward_claimed = false
	state_changed.emit()


func select_part(category: String, part: PartData) -> void:
	if not PartsCatalog.CATEGORIES.has(category):
		return
	if part != null and part.category != category:
		return
	# Passing null clears a slot. Clearing an empty slot changes nothing.
	if part == null:
		if not selected_parts.erase(category):
			return
	else:
		selected_parts[category] = part
	# Both selecting and deselecting invalidate the previously checked build.
	last_result.clear()
	_evaluated_selection.clear()
	state_changed.emit()


func total_cost() -> int:
	return BuildValidator.total_cost(selected_parts)


func has_all_parts() -> bool:
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = selected_parts.get(category)
		if not candidate is PartData or candidate.category != category:
			return false
	return true


func evaluate_build() -> Dictionary:
	last_result = BuildValidator.validate(selected_parts, customer_budget)
	_evaluated_selection = _selection_snapshot()
	_evaluated_budget = customer_budget
	state_changed.emit()
	return last_result


func claim_reward() -> bool:
	if reward_claimed or not last_result.get("success", false):
		return false
	if _evaluated_selection != _selection_snapshot() or _evaluated_budget != customer_budget:
		return false
	# Validate again so edits to a Resource cannot bypass the build checks.
	if not BuildValidator.validate(selected_parts, customer_budget)["success"]:
		return false
	coins += reward_coins
	xp += reward_xp
	reward_claimed = true
	state_changed.emit()
	return true


func _selection_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = selected_parts.get(category)
		if candidate is PartData:
			snapshot[category] = {
				"id": candidate.id,
				"category": candidate.category,
				"display_name": candidate.display_name,
				"price": candidate.price,
				"socket": candidate.socket,
				"ram_type": candidate.ram_type,
				"power_draw": candidate.power_draw,
				"wattage": candidate.wattage,
				"capacity_gb": candidate.capacity_gb,
				"interface_type": candidate.interface_type,
				"supported_storage_interfaces": candidate.supported_storage_interfaces.duplicate(),
			}
	return snapshot
