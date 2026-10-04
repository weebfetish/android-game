class_name JobsCatalog
extends RefCounted
## Five customer jobs, in order of their unlock levels. Resources are independent.


static func get_jobs() -> Array[JobData]:
	return [
		JobData.new("study", "Mika", {
			"personality": "A curious student who likes clear, practical advice.",
			"use_case": "Basic study PC",
			"request": "I need a basic study PC for homework, web browsing, and documents.",
			"budget": 60000, "unlock_level": 1,
			"min_cpu_score": 1, "min_ram_gb": 8, "min_ssd_gb": 256,
			"reward_coins": 5000, "reward_xp": 100, "reward_gems": 1,
		}),
		JobData.new("gaming", "Riku", {
			"personality": "An enthusiastic gamer planning a first gaming setup.",
			"use_case": "Budget gaming PC",
			"request": "I want a gaming PC with a CPU score of at least 2, 16 GB of RAM, and 512 GB of storage.",
			"budget": 85000, "unlock_level": 2,
			"min_cpu_score": 2, "min_ram_gb": 16, "min_ssd_gb": 512,
			"reward_coins": 8000, "reward_xp": 200, "reward_gems": 1,
		}),
		JobData.new("esports", "Hana", {
			"personality": "A focused competitor who enjoys choosing efficient upgrades.",
			"use_case": "Esports PC",
			"request": "Build my esports PC with a CPU score of at least 3, 16 GB of RAM, and 512 GB of storage.",
			"budget": 115000, "unlock_level": 3,
			"min_cpu_score": 3, "min_ram_gb": 16, "min_ssd_gb": 512,
			"reward_coins": 12000, "reward_xp": 300, "reward_gems": 1,
		}),
		JobData.new("creator", "Nao", {
			"personality": "A patient creator who works on videos and illustrations.",
			"use_case": "Content creator PC",
			"request": "I need a creator PC with a CPU score of at least 4, 32 GB of RAM, and a 1 TB NVMe SSD.",
			"budget": 155000, "unlock_level": 4,
			"min_cpu_score": 4, "min_ram_gb": 32, "min_ssd_gb": 1024,
			"storage_interface": "NVMe",
			"reward_coins": 18000, "reward_xp": 400, "reward_gems": 1,
		}),
		JobData.new("workstation", "Daichi", {
			"personality": "A methodical designer with large technical projects.",
			"use_case": "High-end workstation",
			"request": "My workstation needs a CPU score of at least 5, 64 GB of RAM, and a 2 TB NVMe SSD.",
			"budget": 210000, "unlock_level": 5,
			"min_cpu_score": 5, "min_ram_gb": 64, "min_ssd_gb": 2048,
			"storage_interface": "NVMe",
			"reward_coins": 26000, "reward_xp": 500, "reward_gems": 1,
		}),
	]


static func find_job(id: String) -> JobData:
	for job in get_jobs():
		if job.id == id:
			return job
	return null
