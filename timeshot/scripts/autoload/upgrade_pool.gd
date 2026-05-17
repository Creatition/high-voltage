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
	# --- Damage / multiplier upgrades ---
	{
		"id": "damage_1",
		"name": "Hollow Points",
		"description": "+1 bullet damage.",
		"tier": "common",
		"tags": ["damage"],
		"eras": ["any"],
	},
	{
		"id": "damage_2",
		"name": "Depleted Uranium",
		"description": "+3 bullet damage.",
		"tier": "legendary",
		"tags": ["damage"],
		"eras": ["any"],
	},
	{
		"id": "crit_1",
		"name": "Weak Spot Scanner",
		"description": "25% chance for shots to crit (x2 damage).",
		"tier": "rare",
		"tags": ["crit", "damage"],
		"eras": ["any"],
	},
	{
		"id": "crit_2",
		"name": "Surgical Sights",
		"description": "50% crit chance, crits deal x2.5 damage.",
		"tier": "legendary",
		"tags": ["crit", "damage"],
		"eras": ["any"],
	},
	# --- Projectile flight upgrades ---
	{
		"id": "bullet_speed_1",
		"name": "Hot Loads",
		"description": "+25% bullet speed.",
		"tier": "common",
		"tags": ["bullet_speed"],
		"eras": ["any"],
	},
	{
		"id": "range_1",
		"name": "Long Barrel",
		"description": "+50% bullet range.",
		"tier": "common",
		"tags": ["range"],
		"eras": ["any"],
	},
	# --- Spread / fire-rate stacks ---
	{
		"id": "fire_rate_2",
		"name": "Trigger Discipline",
		"description": "+45% fire rate.",
		"tier": "rare",
		"tags": ["fire_rate"],
		"eras": ["any"],
	},
	{
		"id": "shotgun_2",
		"name": "Double-Barrel",
		"description": "Fire 2 more bullets in a spread. Slight fire-rate cost.",
		"tier": "rare",
		"tags": ["spread"],
		"eras": ["any"],
	},
	{
		"id": "pierce_2",
		"name": "Rail Gun Mod",
		"description": "Bullets pierce 3 extra enemies.",
		"tier": "rare",
		"tags": ["pierce"],
		"eras": ["any"],
	},
	{
		"id": "homing_2",
		"name": "Smart Munitions",
		"description": "Bullets aggressively track enemies.",
		"tier": "legendary",
		"tags": ["homing"],
		"eras": ["any"],
	},
	{
		"id": "explosive_2",
		"name": "Warhead Tips",
		"description": "Bullets explode on impact and deal +1 damage.",
		"tier": "legendary",
		"tags": ["explosive", "damage"],
		"eras": ["any"],
	},
	# --- Defense / mobility upgrades ---
	{
		"id": "max_hp_1",
		"name": "Field Rations",
		"description": "+2 max HP and heal that much.",
		"tier": "common",
		"tags": ["health"],
		"eras": ["any"],
	},
	{
		"id": "max_hp_2",
		"name": "Combat Stims",
		"description": "+4 max HP and heal that much.",
		"tier": "rare",
		"tags": ["health"],
		"eras": ["any"],
	},
	{
		"id": "move_speed_1",
		"name": "Quickstep",
		"description": "+15% movement speed.",
		"tier": "common",
		"tags": ["movement"],
		"eras": ["any"],
	},
	{
		"id": "dodge_cooldown_1",
		"name": "Adrenaline",
		"description": "-30% dodge cooldown.",
		"tier": "rare",
		"tags": ["movement", "dodge"],
		"eras": ["any"],
	},
	# --- Curse-style legendary ---
	{
		"id": "glass_cannon",
		"name": "Glass Cannon",
		"description": "+4 bullet damage. -2 max HP.",
		"tier": "legendary",
		"tags": ["damage", "curse"],
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
