class_name PartsCatalog
extends RefCounted
## Starter parts and simple upgrades. Each call returns fresh resources, so callers cannot
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
					"socket": "STUDY-B", "power_draw": 125, "cpu_score": 2,
				}),
				PartData.new("cpu_g8", "cpu", "PlayChip G8", 32000, {
					"socket": "STUDY-B", "power_draw": 150, "cpu_score": 3, "unlock_level": 3,
				}),
				PartData.new("cpu_c12", "cpu", "CreateChip C12", 45000, {
					"socket": "STUDY-B", "power_draw": 180, "cpu_score": 4, "unlock_level": 4,
				}),
				PartData.new("cpu_w16", "cpu", "WorkChip W16", 65000, {
					"socket": "STUDY-B", "power_draw": 240, "cpu_score": 5, "unlock_level": 5,
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
				PartData.new("board_a_plus", "motherboard", "StudyBoard A Plus", 14000, {
					"socket": "STUDY-A", "ram_type": "DDR4", "power_draw": 40,
					"supported_storage_interfaces": ["SATA", "NVMe"], "unlock_level": 2,
				}),
				PartData.new("board_b_plus", "motherboard", "StudyBoard B Plus", 22000, {
					"socket": "STUDY-B", "ram_type": "DDR5", "power_draw": 45,
					"supported_storage_interfaces": ["SATA", "NVMe"], "unlock_level": 2,
				}),
				PartData.new("board_b_pro", "motherboard", "WorkBoard B Pro", 30000, {
					"socket": "STUDY-B", "ram_type": "DDR5", "power_draw": 55,
					"supported_storage_interfaces": ["SATA", "NVMe"], "unlock_level": 4,
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
				PartData.new("ram_ddr4_16", "ram", "StudyRAM 16 GB DDR4", 8000, {
					"ram_type": "DDR4", "capacity_gb": 16, "power_draw": 8, "unlock_level": 2,
				}),
				PartData.new("ram_ddr5_32", "ram", "CreateRAM 32 GB", 15000, {
					"ram_type": "DDR5", "capacity_gb": 32, "power_draw": 12, "unlock_level": 4,
				}),
				PartData.new("ram_ddr5_64", "ram", "WorkRAM 64 GB", 26000, {
					"ram_type": "DDR5", "capacity_gb": 64, "power_draw": 18, "unlock_level": 5,
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
				PartData.new("ssd_nvme_512", "ssd", "PlaySSD 512 GB NVMe", 11000, {
					"interface_type": "NVMe", "capacity_gb": 512, "power_draw": 6, "unlock_level": 2,
				}),
				PartData.new("ssd_nvme_1024", "ssd", "CreateSSD 1 TB NVMe", 18000, {
					"interface_type": "NVMe", "capacity_gb": 1024, "power_draw": 7, "unlock_level": 4,
				}),
				PartData.new("ssd_nvme_2048", "ssd", "WorkSSD 2 TB NVMe", 32000, {
					"interface_type": "NVMe", "capacity_gb": 2048, "power_draw": 10, "unlock_level": 5,
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
				PartData.new("psu_450", "psu", "PlayPower 450 W", 12000, {
					"wattage": 450, "unlock_level": 2,
				}),
				PartData.new("psu_550", "psu", "CreatePower 550 W", 15000, {
					"wattage": 550, "unlock_level": 3,
				}),
				PartData.new("psu_750", "psu", "WorkPower 750 W", 22000, {
					"wattage": 750, "unlock_level": 5,
				}),
			]
	return []


static func get_unlocked_parts(category: String, level: int) -> Array[PartData]:
	var unlocked: Array[PartData] = []
	for part in get_parts(category):
		if part.unlock_level <= level:
			unlocked.append(part)
	return unlocked


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
			return "Socket: %s | CPU score: %d | Power: %d W" % [part.socket, part.cpu_score, part.power_draw]
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
