class_name PartsCatalog
extends RefCounted
## The ten starter parts. Each call returns fresh resources, so callers cannot
## accidentally change the catalog for another customer.

const CATEGORIES: Array[String] = ["cpu", "motherboard", "ram", "ssd", "psu"]


static func get_parts(category: String) -> Array[PartData]:
	match category:
		"cpu":
			return [
				PartData.new("cpu_s4", "cpu", "StudyChip S4", 12000, {
					"socket": "STUDY-A", "power_draw": 65,
				}),
				PartData.new("cpu_p6", "cpu", "StudyChip P6", 20000, {
					"socket": "STUDY-B", "power_draw": 125,
				}),
			]
		"motherboard":
			return [
				PartData.new("board_a", "motherboard", "StudyBoard A", 10000, {
					"socket": "STUDY-A", "ram_type": "DDR4", "power_draw": 35,
					"supported_storage_interfaces": ["SATA"],
				}),
				PartData.new("board_b", "motherboard", "StudyBoard B", 16000, {
					"socket": "STUDY-B", "ram_type": "DDR5", "power_draw": 40,
					"supported_storage_interfaces": ["SATA"],
				}),
			]
		"ram":
			return [
				PartData.new("ram_ddr4", "ram", "StudyRAM 8 GB", 5000, {
					"ram_type": "DDR4", "capacity_gb": 8, "power_draw": 5,
				}),
				PartData.new("ram_ddr5", "ram", "StudyRAM 16 GB", 9000, {
					"ram_type": "DDR5", "capacity_gb": 16, "power_draw": 8,
				}),
			]
		"ssd":
			return [
				PartData.new("ssd_256", "ssd", "StudySSD 256 GB", 5000, {
					"interface_type": "SATA", "capacity_gb": 256, "power_draw": 4,
				}),
				PartData.new("ssd_512", "ssd", "StudySSD 512 GB", 8000, {
					"interface_type": "SATA", "capacity_gb": 512, "power_draw": 5,
				}),
			]
		"psu":
			return [
				PartData.new("psu_180", "psu", "StudyPower 180 W", 6000, {
					"wattage": 180,
				}),
				PartData.new("psu_350", "psu", "StudyPower 350 W", 10000, {
					"wattage": 350,
				}),
			]
	return []


static func find_part(id: String) -> PartData:
	for category in CATEGORIES:
		for part in get_parts(category):
			if part.id == id:
				return part
	return null


static func category_label(category: String) -> String:
	match category:
		"cpu":
			return "CPU"
		"motherboard":
			return "Motherboard"
		"ram":
			return "RAM"
		"ssd":
			return "SSD"
		"psu":
			return "PSU"
	return category.capitalize()


static func describe_part(part: PartData) -> String:
	if part == null:
		return "No part selected."
	match part.category:
		"cpu":
			return "Socket: %s | Power: %d W" % [part.socket, part.power_draw]
		"motherboard":
			return "Socket: %s | RAM: %s | Storage: %s | Power: %d W" % [
				part.socket, part.ram_type,
				", ".join(part.supported_storage_interfaces), part.power_draw,
			]
		"ram":
			return "%s | Capacity: %d GB | Power: %d W" % [
				part.ram_type, part.capacity_gb, part.power_draw,
			]
		"ssd":
			return "%s | Capacity: %d GB | Power: %d W" % [
				part.interface_type, part.capacity_gb, part.power_draw,
			]
		"psu":
			return "Supplies up to %d W" % part.wattage
	return "No specifications."
