extends RefCounted
class_name EnemyTable
## Per-era roster of enemies/traps the generator can pull from.
##
## Each era has three pools — "grunts" (cheap), "specials" (medium budget),
## "elites" (high budget). The populator buys spawns out of a per-room budget
## that scales with the cell's depth from start.
##
## This is data only; the runtime spawner (Day 7) takes these ids and resolves
## them to actual PackedScenes from res://scenes/enemies/.

static func enemy_pools(era: String) -> Dictionary:
	# Day 22 — the swarmer/bomber/sniper trio joins every era's roster so
	# fights have more variety and force-mixed counter-play (kite the bomber,
	# break line-of-sight on the sniper, run from swarms).
	match era:
		"present":
			return {
				"grunts":   ["drone", "hacker", "swarmer"],
				"specials": ["hacker", "bomber"],
				"elites":   ["hacker", "sniper"],
				"traps":    ["pressure_plate", "dart_shooter"],
			}
		"prehistoric":
			return {
				"grunts":   ["raptor", "swarmer"],
				"specials": ["pterodactyl", "bomber"],
				"elites":   ["pterodactyl"],
				"traps":    ["spike_pit"],
			}
		"medieval":
			return {
				"grunts":   ["knight", "swarmer"],
				"specials": ["archer", "bomber"],
				"elites":   ["archer", "sniper"],
				"traps":    ["pressure_plate"],
			}
		"future", "cyberpunk":
			return {
				"grunts":   ["drone", "hacker", "swarmer"],
				"specials": ["hacker", "bomber"],
				"elites":   ["hacker", "sniper"],
				"traps":    ["dart_shooter"],
			}
		"alien":
			return {
				"grunts":   ["alien_grunt", "swarmer"],
				"specials": ["alien_sentry", "bomber"],
				"elites":   ["alien_sentry", "sniper"],
				"traps":    ["spike_pit"],
			}
		"aztec":
			return {
				"grunts":   ["chaser", "swarmer"],
				"specials": ["shooter", "bomber"],
				"elites":   ["shooter", "sniper"],
				"traps":    ["dart_shooter", "spike_pit"],
			}
		"egypt":
			return {
				"grunts":   ["chaser", "swarmer"],
				"specials": ["shooter", "bomber"],
				"elites":   ["shooter", "sniper"],
				"traps":    ["dart_shooter", "spike_pit"],
			}
		_:
			return {
				"grunts":   ["chaser", "swarmer"],
				"specials": ["shooter", "bomber"],
				"elites":   ["shooter", "sniper"],
				"traps":    ["pressure_plate"],
			}


static func boss_id(era: String) -> String:
	match era:
		"prehistoric":    return "trex"
		"medieval":       return "black_knight"
		"alien":          return "alien_mothership"
		"future", "cyberpunk": return "ai_core"
		"present":        return "present_miniboss"
	return "present_miniboss"
