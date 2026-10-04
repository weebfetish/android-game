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


static func validate(parts: Dictionary, budget: int, requirements: Dictionary = {}) -> Dictionary:
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
	_add_customer_requirements(checks, reasons, cpu, ram, ssd, requirements)

	return {
		"success": reasons.is_empty(),
		"reasons": reasons,
		"checks": checks,
		"total_cost": cost,
		"required_power": power,
		"psu_wattage": supplied_power,
		"budget": budget,
	}


static func _add_customer_requirements(
	checks: Array[Dictionary], reasons: PackedStringArray,
	cpu: PartData, ram: PartData, ssd: PartData, requirements: Dictionary
) -> void:
	if cpu != null and requirements.has("min_cpu_score"):
		var minimum_score: int = int(requirements["min_cpu_score"])
		_add_check(checks, reasons, cpu.cpu_score >= minimum_score, "Customer CPU requirement",
			"CPU score: %d. Customer needs at least %d." % [cpu.cpu_score, minimum_score])
	if ram != null and requirements.has("min_ram_gb"):
		var minimum_ram: int = int(requirements["min_ram_gb"])
		_add_check(checks, reasons, ram.capacity_gb >= minimum_ram, "Customer RAM requirement",
			"RAM capacity: %d GB. Customer needs at least %d GB." % [ram.capacity_gb, minimum_ram])
	if ssd != null and requirements.has("min_ssd_gb"):
		var minimum_storage: int = int(requirements["min_ssd_gb"])
		_add_check(checks, reasons, ssd.capacity_gb >= minimum_storage, "Customer storage capacity",
			"SSD capacity: %d GB. Customer needs at least %d GB." % [ssd.capacity_gb, minimum_storage])
	var required_interface: String = String(requirements.get("storage_interface", ""))
	if ssd != null and not required_interface.is_empty():
		_add_check(checks, reasons, ssd.interface_type == required_interface, "Customer storage interface",
			"SSD interface: %s. Customer requests %s." % [ssd.interface_type, required_interface])


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
