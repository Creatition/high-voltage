extends Node
## Upgrade pool registry. Will eventually load .tres Resource files from
## resources/upgrades/, but for the prototype we keep an inline dictionary
## so we can iterate fast.

# Upgrade schema:
#   id:          stable string used by Player._apply_upgrade() and saves
#   name:        display name on cards / HUD pips
#   description: short flavor + mechanical line shown on the upgrade card
#   tier:        "common" | "rare" | "legendary" — drives weighting
#   tags:        category tags for filtering / synergy detection
#   eras:        which eras this can drop in ("any" allows everywhere)
var pool: Array = [
	{
		"id": "fire_rate_1",
		"name": "Lightning Reflexes",
		"description": "+30% fire rate.",
		"tier": "common",
		"tags": ["fire_rate"],
		"eras": ["any"],
	},
	{
		"id": "shotgun_1",
		"name": "Spread Shot",
		"description": "Fire 2 extra bullets in a spread.",
		"tier": "common",
		"tags": ["spread"],
		"eras": ["any"],
	},
	{
		"id": "bouncing_1",
		"name": "Ricochet Rounds",
		"description": "Bullets bounce off walls 2 times.",
		"tier": "common",
		"tags": ["bouncing"],
		"eras": ["any"],
	},
	{
		"id": "pierce_1",
		"name": "Piercing Slug",
		"description": "Bullets pierce 1 extra enemy.",
		"tier": "common",
		"tags": ["pierce"],
		"eras": ["any"],
	},
	{
		"id": "homing_1",
		"name": "Heat Seekers",
		"description": "Bullets curve toward enemies. Slight fire-rate cost.",
		"tier": "rare",
		"tags": ["homing"],
		"eras": ["any"],
	},
	{
		"id": "explosive_1",
		"name": "Boomstick",
		"description": "Bullets explode on impact. Mind the splash.",
		"tier": "rare",
		"tags": ["explosive"],
		"eras": ["any"],
	},
]

const TIER_WEIGHTS := {
	"common": 5,
	"rare": 2,
	"legendary": 1,
}


## Returns N unique random upgrades, optionally era-filtered.
func roll(count: int = 3, era: String = "any") -> Array:
	var available := []
	for upgrade in pool:
		if not _era_allows(upgrade, era):
			continue
		available.append(upgrade)
	var picks: Array = []
	while picks.size() < count and available.size() > 0:
		var pick := _weighted_pick(available)
		picks.append(pick)
		available.erase(pick)
	return picks


func _weighted_pick(items: Array) -> Dictionary:
	var total := 0
	for item in items:
		total += TIER_WEIGHTS.get(item.get("tier", "common"), 1)
	var roll_value := randi() % maxi(total, 1)
	var cursor := 0
	for item in items:
		cursor += TIER_WEIGHTS.get(item.get("tier", "common"), 1)
		if roll_value < cursor:
			return item
	return items.back()


func _era_allows(upgrade: Dictionary, era: String) -> bool:
	if era == "any":
		return true
	var eras: Array = upgrade.get("eras", ["any"])
	return "any" in eras or era in eras


func get_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in pool:
		if upgrade["id"] == upgrade_id:
			return upgrade
	return {}
