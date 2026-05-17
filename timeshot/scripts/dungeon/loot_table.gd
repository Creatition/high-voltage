extends RefCounted
class_name LootTable
## Per-cell loot planning. The generator runs this after rooms are tagged
## and populated; each room gets a "loot plan" stored as cell metadata that
## the runtime spawner reads when stamping the template's `*` glyphs.
##
## Drop kinds:
##   "shard"   — small time-shard pickup (currency)
##   "heart"   — health pickup
##   "upgrade" — single upgrade pickup (rare)
##   "chest"   — guaranteed multi-drop chest (shrine/secret only)

static func plan_for(cell: DungeonCell, rng: RandomNumberGenerator) -> Dictionary:
	match cell.type:
		DungeonCell.Type.START:
			return {"drops": []}
		DungeonCell.Type.SHOP:
			# Shops handle their own inventory via ShopTerminal.
			return {"drops": []}
		DungeonCell.Type.SHRINE:
			return {"drops": ["chest"]}
		DungeonCell.Type.SECRET:
			# Secret rooms are the carrot for going off-path.
			return {"drops": ["chest", "upgrade"]}
		DungeonCell.Type.BOSS:
			return {"drops": ["chest", "heart"]}
		DungeonCell.Type.ELITE:
			return {"drops": _roll_elite_drops(rng, cell.depth)}
		DungeonCell.Type.NORMAL:
			return {"drops": _roll_normal_drops(rng, cell.depth)}
	return {"drops": []}


static func _roll_normal_drops(rng: RandomNumberGenerator, depth: int) -> Array:
	var out: Array = []
	# Always at least one shard so combat rooms feel rewarding.
	out.append("shard")
	if rng.randf() < 0.45:
		out.append("shard")
	if rng.randf() < 0.12 + depth * 0.02:
		out.append("heart")
	if rng.randf() < 0.05 + depth * 0.01:
		out.append("upgrade")
	return out


static func _roll_elite_drops(rng: RandomNumberGenerator, depth: int) -> Array:
	var out: Array = ["shard", "shard"]
	if rng.randf() < 0.55:
		out.append("heart")
	if rng.randf() < 0.25 + depth * 0.02:
		out.append("upgrade")
	return out
