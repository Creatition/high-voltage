extends Node
## Codex / bestiary: tracks which enemies, bosses, upgrades, and lore notes the
## player has encountered. Each entry has a discovery state (UNKNOWN / SPOTTED
## / DEFEATED / MASTERED) and an optional lore blurb that unlocks at SPOTTED.
##
## Not yet registered as an autoload — add `Codex="*res://scripts/autoload/codex.gd"`
## under [autoload] in project.godot when wiring it in.
##
## Gameplay code calls Codex.spot(id), Codex.defeat(id), Codex.collect(id) as
## relevant. Cheap to call repeatedly; only writes to disk on state change.

signal entry_updated(id: String, new_state: int)

enum State { UNKNOWN, SPOTTED, DEFEATED, MASTERED }
enum Kind { ENEMY, BOSS, UPGRADE, ITEM, LORE }

const SAVE_PATH := "user://timeshot_codex.json"
const VERSION := 1

## Catalog. Tweak freely; keys must match the IDs gameplay code passes in.
const CATALOG := {
	# Enemies
	"chaser":         {"kind": Kind.ENEMY, "title": "Chaser", "era": "present", "lore": "Wired and reckless. Runs straight at the noise."},
	"shooter":        {"kind": Kind.ENEMY, "title": "Shooter", "era": "present", "lore": "Stays at range. Telegraphs every shot."},
	"bomber":         {"kind": Kind.ENEMY, "title": "Bomber", "era": "present", "lore": "Walking ordnance with a death wish."},
	"swarmer":        {"kind": Kind.ENEMY, "title": "Swarmer", "era": "present", "lore": "Weak alone. Numerous."},
	"raptor":         {"kind": Kind.ENEMY, "title": "Raptor", "era": "prehistoric", "lore": "Clever pack hunter. Flanks."},
	"pterodactyl":    {"kind": Kind.ENEMY, "title": "Pterodactyl", "era": "prehistoric", "lore": "Dive-bombs from above. Ignores most cover."},
	"archer":         {"kind": Kind.ENEMY, "title": "Archer", "era": "medieval", "lore": "Aim is true at long distance. Slow to draw."},
	"knight":         {"kind": Kind.ENEMY, "title": "Knight", "era": "medieval", "lore": "Heavily armored. Strike at the gaps."},
	"sniper":         {"kind": Kind.ENEMY, "title": "Sniper", "era": "west", "lore": "A red dot is a warning, not a guarantee."},
	"hacker":         {"kind": Kind.ENEMY, "title": "Hacker", "era": "future", "lore": "Inverts your controls when in line-of-sight."},
	"drone":          {"kind": Kind.ENEMY, "title": "Drone", "era": "future", "lore": "Fragile. Patrols in tight formations."},
	"alien_grunt":    {"kind": Kind.ENEMY, "title": "Alien Grunt", "era": "future", "lore": "Cannon fodder. Bleeds blue."},
	"alien_sentry":   {"kind": Kind.ENEMY, "title": "Alien Sentry", "era": "future", "lore": "Stationary, shielded, sees in 360."},

	# Bosses
	"trex":             {"kind": Kind.BOSS, "title": "T-Rex", "era": "prehistoric", "lore": "The boss fused with the apex predator. Ground shakes."},
	"black_knight":     {"kind": Kind.BOSS, "title": "Black Knight", "era": "medieval", "lore": "The boss in stolen plate, blade still wet."},
	"ai_core":          {"kind": Kind.BOSS, "title": "AI Core", "era": "future", "lore": "The boss uploaded themself. Bring a Faraday cage."},
	"alien_mothership": {"kind": Kind.BOSS, "title": "Mothership", "era": "future", "lore": "Whatever they found out there, they brought it back."},
	"present_miniboss": {"kind": Kind.BOSS, "title": "The Thief", "era": "present", "lore": "First glimpse, last warning."},

	# Items / pickups
	"time_shard":       {"kind": Kind.ITEM, "title": "Time Shard", "era": "any", "lore": "A piece of broken hour. Worth something to someone."},

	# Lore notes (collected from secret rooms)
	"note_01_garage":   {"kind": Kind.LORE, "title": "Workshop Log #1", "era": "present", "lore": "\"...I told them it wasn't ready. They took it anyway.\""},
	"note_02_pyramid":  {"kind": Kind.LORE, "title": "Hieroglyph Fragment", "era": "egypt", "lore": "A figure with a strange weapon. The cartouche is scratched out."},
	"note_03_saloon":   {"kind": Kind.LORE, "title": "Bounty Poster", "era": "west", "lore": "WANTED. Crime: \"stealing time itself.\" Reward: undisclosed."},
}

var _entries: Dictionary = {}  # id -> State int


func _ready() -> void:
	_load()


func state_of(id: String) -> int:
	return int(_entries.get(id, State.UNKNOWN))


func is_known(id: String) -> bool:
	return state_of(id) != State.UNKNOWN


## Mark that the player has SEEN this entity in the wild.
func spot(id: String) -> void:
	_promote(id, State.SPOTTED)


## Mark that the player has KILLED this enemy / boss or USED this item.
func defeat(id: String) -> void:
	_promote(id, State.DEFEATED)


## Lore notes / journal pages — discrete pickups.
func collect(id: String) -> void:
	_promote(id, State.DEFEATED)


## Optional top tier — e.g., kill a boss without taking damage, find every
## variant of an enemy, etc.
func master(id: String) -> void:
	_promote(id, State.MASTERED)


func _promote(id: String, new_state: int) -> void:
	if not CATALOG.has(id):
		push_warning("Codex: unknown entry %s" % id)
		return
	var cur := state_of(id)
	if new_state <= cur:
		return
	_entries[id] = new_state
	emit_signal("entry_updated", id, new_state)
	_save()


func title_of(id: String) -> String:
	if not is_known(id):
		return "???"
	return String(CATALOG.get(id, {}).get("title", id))


func lore_of(id: String) -> String:
	if state_of(id) < State.SPOTTED:
		return ""
	return String(CATALOG.get(id, {}).get("lore", ""))


func entries_by_kind(kind: int) -> Array:
	var out: Array = []
	for id in CATALOG.keys():
		if int(CATALOG[id].get("kind", -1)) == kind:
			out.append(id)
	return out


func entries_by_era(era_id: String) -> Array:
	var out: Array = []
	for id in CATALOG.keys():
		if String(CATALOG[id].get("era", "")) == era_id:
			out.append(id)
	return out


func known_count() -> int:
	return _entries.size()


func total_count() -> int:
	return CATALOG.size()


func completion() -> float:
	if CATALOG.is_empty():
		return 0.0
	return float(known_count()) / float(CATALOG.size())


## --- Persistence ---

func _save() -> void:
	var data := {
		"version": VERSION,
		"entries": _entries,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Codex: cannot write save")
		return
	f.store_string(JSON.stringify(data))
	f.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var e: Variant = data.get("entries", {})
	if e is Dictionary:
		for k in (e as Dictionary).keys():
			_entries[String(k)] = int((e as Dictionary)[k])
