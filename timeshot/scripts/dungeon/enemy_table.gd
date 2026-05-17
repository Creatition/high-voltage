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
	match era:
		"present":
			return {
				"grunts":   ["drone", "hacker"],
				"specials": ["hacker"],
				"elites":   ["hacker"],
				"traps":    ["pressure_plate", "dart_shooter"],
			}
		"prehistoric":
			return {
				"grunts":   ["raptor"],
				"specials": ["pterodactyl"],
				"elites":   ["pterodactyl"],
				"traps":    ["spike_pit"],
			}
		"medieval":
			return {
				"grunts":   ["knight"],
				"specials": ["archer"],
				"elites":   ["archer"],
				"traps":    ["pressure_plate"],
			}
		"future", "cyberpunk":
			return {
				"grunts":   ["drone", "hacker"],
				"specials": ["hacker"],
				"elites":   ["hacker"],
				"traps":    ["dart_shooter"],
			}
		"alien":
			return {
				"grunts":   ["alien_grunt"],
				"specials": ["alien_sentry"],
				"elites":   ["alien_sentry"],
				"traps":    ["spike_pit"],
			}
		"aztec":
			return {
				"grunts":   ["chaser"],
				"specials": ["shooter"],
				"elites":   ["shooter"],
				"traps":    ["dart_shooter", "spike_pit"],
			}
		"egypt":
			return {
				"grunts":   ["chaser"],
				"specials": ["shooter"],
				"elites":   ["shooter"],
				"traps":    ["dart_shooter", "spike_pit"],
			}
		_:
			return {
				"grunts":   ["chaser"],
				"specials": ["shooter"],
				"elites":   ["shooter"],
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
