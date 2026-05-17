extends Node
## Upgrade pool registry. Will eventually load .tres Resource files from
## resources/upgrades/, but for the prototype we keep an inline dictionary
## so we can iterate fast.

# Upgrade schema:
#   id:          stable string used by Player._apply_upgrade() and saves
#   name:        display name on cards / HUD pips
#   description: short flavor + mechanical line shown on the upgrade card
#   tier:        "common" | "uncommon" | "rare" | "epic" | "legendary"
#                — drives weighting AND visual rarity styling in the picker
#   tags:        category tags for filtering / synergy detection
#   eras:        which eras this can drop in ("any" allows everywhere)
#
# Day 23 pass:
#  - Numeric values trimmed ~30-50% across the board so stacking 4-5 upgrades
#    is interesting, not game-breaking.
#  - Added UNCOMMON + EPIC tiers; legendaries now genuinely rare.
#  - Adjusted weights so a level-up pick of 3 cards usually surfaces 2-3
#    commons / uncommons and only occasionally a rare-or-better.
var pool: Array = [
	# ===== COMMON =====
	{
		"id": "fire_rate_1",
		"name": "Lightning Reflexes",
		"description": "+18% fire rate.",
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
		"description": "Bullets bounce off walls once.",
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
		"id": "damage_1",
		"name": "Hollow Points",
		"description": "+1 bullet damage.",
		"tier": "common",
		"tags": ["damage"],
		"eras": ["any"],
	},
	{
		"id": "bullet_speed_1",
		"name": "Hot Loads",
		"description": "+15% bullet speed.",
		"tier": "common",
		"tags": ["bullet_speed"],
		"eras": ["any"],
	},
	{
		"id": "range_1",
		"name": "Long Barrel",
		"description": "+30% bullet range.",
		"tier": "common",
		"tags": ["range"],
		"eras": ["any"],
	},
	{
		"id": "max_hp_1",
		"name": "Field Rations",
		"description": "+1 max HP and heal that much.",
		"tier": "common",
		"tags": ["health"],
		"eras": ["any"],
	},
	{
		"id": "move_speed_1",
		"name": "Quickstep",
		"description": "+8% movement speed.",
		"tier": "common",
		"tags": ["movement"],
		"eras": ["any"],
	},
	# ===== UNCOMMON =====
	{
		"id": "fire_rate_2",
		"name": "Trigger Discipline",
		"description": "+30% fire rate.",
		"tier": "uncommon",
		"tags": ["fire_rate"],
		"eras": ["any"],
	},
	{
		"id": "max_hp_2",
		"name": "Combat Stims",
		"description": "+2 max HP and heal that much.",
		"tier": "uncommon",
		"tags": ["health"],
		"eras": ["any"],
	},
	{
		"id": "bullet_speed_2",
		"name": "Magnetic Rails",
		"description": "+25% bullet speed.",
		"tier": "uncommon",
		"tags": ["bullet_speed"],
		"eras": ["any"],
	},
	{
		"id": "iframes_1",
		"name": "Slipstream",
		"description": "+0.08s dodge invulnerability.",
		"tier": "uncommon",
		"tags": ["movement", "dodge"],
		"eras": ["any"],
	},
	{
		"id": "dodge_cooldown_1",
		"name": "Adrenaline",
		"description": "-20% dodge cooldown.",
		"tier": "uncommon",
		"tags": ["movement", "dodge"],
		"eras": ["any"],
	},
	# ===== RARE =====
	{
		"id": "homing_1",
		"name": "Heat Seekers",
		"description": "Bullets curve toward enemies. Slight fire-rate cost.",
		"tier": "rare",
		"tags": ["homing"],
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
		"id": "crit_1",
		"name": "Weak Spot Scanner",
		"description": "15% chance for shots to crit (x2 damage).",
		"tier": "rare",
		"tags": ["crit", "damage"],
		"eras": ["any"],
	},
	{
		"id": "bouncing_2",
		"name": "Quantum Ricochet",
		"description": "Bullets bounce 2 more times and gain +10% speed per bounce.",
		"tier": "rare",
		"tags": ["bouncing"],
		"eras": ["any"],
	},
	# ===== EPIC =====
	{
		"id": "pierce_2",
		"name": "Rail Gun Mod",
		"description": "Bullets pierce 2 extra enemies.",
		"tier": "epic",
		"tags": ["pierce"],
		"eras": ["any"],
	},
	{
		"id": "damage_2",
		"name": "Depleted Uranium",
		"description": "+2 bullet damage.",
		"tier": "epic",
		"tags": ["damage"],
		"eras": ["any"],
	},
	{
		"id": "explosive_1",
		"name": "Boomstick",
		"description": "Bullets explode on impact. Mind the splash.",
		"tier": "epic",
		"tags": ["explosive"],
		"eras": ["any"],
	},
	# ===== LEGENDARY =====
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
	{
		"id": "crit_2",
		"name": "Surgical Sights",
		"description": "30% crit chance, crits deal x2.25 damage.",
		"tier": "legendary",
		"tags": ["crit", "damage"],
		"eras": ["any"],
	},
	{
		"id": "glass_cannon",
		"name": "Glass Cannon",
		"description": "+3 bullet damage. -1 max HP.",
		"tier": "legendary",
		"tags": ["damage", "curse"],
		"eras": ["any"],
	},
]

const TIER_WEIGHTS := {
	"common": 16,
	"uncommon": 9,
	"rare": 4,
	"epic": 2,
	"legendary": 1,
}

const TIER_ORDER := ["common", "uncommon", "rare", "epic", "legendary"]


## Returns N unique random upgrades, optionally era-filtered.
## `min_tier` raises the floor (e.g. level 5+ might guarantee uncommon+).
func roll(count: int = 3, era: String = "any", min_tier: String = "common") -> Array:
	var min_idx: int = TIER_ORDER.find(min_tier)
	if min_idx < 0:
		min_idx = 0
	var available := []
	for upgrade in pool:
		if not _era_allows(upgrade, era):
			continue
		var tier_idx: int = TIER_ORDER.find(String(upgrade.get("tier", "common")))
		if tier_idx < min_idx:
			continue
		available.append(upgrade)
	var picks: Array = []
	while picks.size() < count and available.size() > 0:
		var pick := _weighted_pick(available)
		picks.append(pick)
		available.erase(pick)
	return picks


func _weighted_pick(items: Array) -> Dictionary:
	var total: int = 0
	for item in items:
		total += int(TIER_WEIGHTS.get(item.get("tier", "common"), 1))
	var roll_value: int = randi() % maxi(total, 1)
	var cursor: int = 0
	for item in items:
		cursor += int(TIER_WEIGHTS.get(item.get("tier", "common"), 1))
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
