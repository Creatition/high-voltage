extends Node
## Upgrade pool registry. Stub for the prototype.
## Will hold all available Chrono-Pistol upgrades and provide random pulls
## filtered by era, rarity, and exclusions.

# Placeholder pool — replace with .tres Resource files in resources/upgrades/ later.
var pool: Array = [
	{"id": "fire_rate_1",   "name": "Lightning Reflexes",   "tier": "common", "tags": ["fire_rate"]},
	{"id": "bouncing_1",    "name": "Ricochet Rounds",      "tier": "common", "tags": ["bouncing"]},
	{"id": "homing_1",      "name": "Heat Seekers",         "tier": "rare",   "tags": ["homing"]},
	{"id": "explosive_1",   "name": "Boomstick",            "tier": "rare",   "tags": ["explosive"]},
	{"id": "shotgun_1",     "name": "Spread Shot",          "tier": "common", "tags": ["spread"]},
]


## Returns N unique random upgrades.
func roll(count: int = 3) -> Array:
	var available := pool.duplicate()
	available.shuffle()
	return available.slice(0, mini(count, available.size()))


func get_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in pool:
		if upgrade["id"] == upgrade_id:
			return upgrade
	return {}
