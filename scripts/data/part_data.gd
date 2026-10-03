class_name PartData
extends Resource
## One shop part. Prices and specifications are deliberately fictional.

@export var id: String = ""
@export var category: String = ""
@export var display_name: String = ""
@export var price: int = 0
@export var socket: String = ""
@export var ram_type: String = ""
@export var power_draw: int = 0
@export var wattage: int = 0
@export var capacity_gb: int = 0
@export var interface_type: String = ""
@export var supported_storage_interfaces: PackedStringArray = []


func _init(
	part_id: String = "",
	part_category: String = "",
	part_name: String = "",
	part_price: int = 0,
	specifications: Dictionary = {}
) -> void:
	id = part_id
	category = part_category
	display_name = part_name
	price = part_price
	socket = String(specifications.get("socket", ""))
	ram_type = String(specifications.get("ram_type", ""))
	power_draw = int(specifications.get("power_draw", 0))
	wattage = int(specifications.get("wattage", 0))
	capacity_gb = int(specifications.get("capacity_gb", 0))
	interface_type = String(specifications.get("interface_type", ""))
	supported_storage_interfaces = PackedStringArray(
		specifications.get("supported_storage_interfaces", [])
	)
