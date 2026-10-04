class_name JobData
extends Resource
## One customer job. Requirements and rewards are fictional game values.

@export var id: String = ""
@export var name: String = ""
@export var personality: String = ""
@export var use_case: String = ""
@export var request: String = ""
@export var budget: int = 60000
@export var unlock_level: int = 1
@export var min_cpu_score: int = 1
@export var min_ram_gb: int = 8
@export var min_ssd_gb: int = 256
@export var storage_interface: String = ""
@export var reward_coins: int = 5000
@export var reward_xp: int = 100
@export var reward_gems: int = 1


func _init(job_id: String = "", customer_name: String = "", specifications: Dictionary = {}) -> void:
	id = job_id
	name = customer_name
	personality = String(specifications.get("personality", ""))
	use_case = String(specifications.get("use_case", ""))
	request = String(specifications.get("request", ""))
	budget = int(specifications.get("budget", 60000))
	unlock_level = int(specifications.get("unlock_level", 1))
	min_cpu_score = int(specifications.get("min_cpu_score", 1))
	min_ram_gb = int(specifications.get("min_ram_gb", 8))
	min_ssd_gb = int(specifications.get("min_ssd_gb", 256))
	storage_interface = String(specifications.get("storage_interface", ""))
	reward_coins = int(specifications.get("reward_coins", 5000))
	reward_xp = int(specifications.get("reward_xp", 100))
	reward_gems = int(specifications.get("reward_gems", 1))


func requirements() -> Dictionary:
	return {
		"min_cpu_score": min_cpu_score,
		"min_ram_gb": min_ram_gb,
		"min_ssd_gb": min_ssd_gb,
		"storage_interface": storage_interface,
	}
