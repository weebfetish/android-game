class_name BuildValidator
extends RefCounted
## Pure checks: the validator never changes the selected parts or player state.

# The prototype includes a fixed case and cooling system, without shop items.
const BASE_POWER_DRAW: int = 30


static func total_cost(parts: Dictionary) -> int:
	var total: int = 0
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = parts.get(category)
		if candidate is PartData:
			total += candidate.price
	return total


static func required_power(parts: Dictionary) -> int:
	var total: int = BASE_POWER_DRAW
	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = parts.get(category)
		if candidate is PartData:
			total += candidate.power_draw
	return total


static func validate(parts: Dictionary, budget: int) -> Dictionary:
	var reasons: PackedStringArray = []
	var checks: Array[Dictionary] = []
	var selection_problems: PackedStringArray = []

	for category in PartsCatalog.CATEGORIES:
		var candidate: Variant = parts.get(category)
		if not candidate is PartData:
			selection_problems.append("Select one %s." % PartsCatalog.category_label(category))
		elif candidate.category != category:
			selection_problems.append("%s slot requires a %s; %s is a %s." % [
				PartsCatalog.category_label(category), PartsCatalog.category_label(category),
				candidate.display_name, PartsCatalog.category_label(candidate.category),
			])

	for key in parts:
		if not PartsCatalog.CATEGORIES.has(key):
			selection_problems.append("Unknown part slot: %s." % str(key))

	var selection_detail: String = "One CPU, motherboard, RAM, SSD, and PSU selected."
	if not selection_problems.is_empty():
		selection_detail = " ".join(selection_problems)
	_add_check(checks, reasons, selection_problems.is_empty(), "Required parts", selection_detail)

	var cpu: PartData = _part_for_slot(parts, "cpu")
	var motherboard: PartData = _part_for_slot(parts, "motherboard")
	var ram: PartData = _part_for_slot(parts, "ram")
	var ssd: PartData = _part_for_slot(parts, "ssd")
	var psu: PartData = _part_for_slot(parts, "psu")

	if cpu != null and motherboard != null:
		_add_check(checks, reasons, cpu.socket == motherboard.socket,
			"CPU / motherboard compatibility",
			"CPU socket: %s. Motherboard socket: %s. These must match." % [
				cpu.socket, motherboard.socket,
			])

	if ram != null and motherboard != null:
		_add_check(checks, reasons, ram.ram_type == motherboard.ram_type,
			"RAM / motherboard compatibility",
			"RAM type: %s. Motherboard accepts: %s. These must match." % [
				ram.ram_type, motherboard.ram_type,
			])

	if ssd != null and motherboard != null:
		_add_check(checks, reasons,
			motherboard.supported_storage_interfaces.has(ssd.interface_type),
			"SSD / motherboard compatibility",
			"SSD interface: %s. Motherboard supports: %s." % [
				ssd.interface_type, ", ".join(motherboard.supported_storage_interfaces),
			])

	var power: int = required_power(parts)
	var supplied_power: int = 0
	if psu != null:
		supplied_power = psu.wattage
		_add_check(checks, reasons, supplied_power >= power, "PSU capacity",
			"Build needs %d W, including %d W for the fixed case and cooling. PSU supplies %d W." % [
				power, BASE_POWER_DRAW, supplied_power,
			])

	var cost: int = total_cost(parts)
	_add_check(checks, reasons, cost <= budget, "Customer budget",
		"Parts cost %d coins. Customer budget: %d coins." % [cost, budget])

	return {
		"success": reasons.is_empty(),
		"reasons": reasons,
		"checks": checks,
		"total_cost": cost,
		"required_power": power,
		"psu_wattage": supplied_power,
		"budget": budget,
	}


static func _part_for_slot(parts: Dictionary, category: String) -> PartData:
	var candidate: Variant = parts.get(category)
	if candidate is PartData and candidate.category == category:
		return candidate
	return null


static func _add_check(
	checks: Array[Dictionary], reasons: PackedStringArray,
	passed: bool, title: String, detail: String
) -> void:
	checks.append({"passed": passed, "title": title, "detail": detail})
	if not passed:
		reasons.append("%s: %s" % [title, detail])
