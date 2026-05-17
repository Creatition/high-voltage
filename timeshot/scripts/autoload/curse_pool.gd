extends Node
## Curse pool: optional run modifiers with steep upside and a real downside.
##
## Not yet registered as an autoload — add `CursePool="*res://scripts/autoload/curse_pool.gd"`
## under [autoload] in project.godot when wiring it in.
##
## Design intent:
##   * Curses are picked BEFORE a run starts (curse altar in the hub) and
##     persist for the whole run.
##   * Each curse stacks ONE upside and ONE downside, so the player is making
##     a real tradeoff, not a free buff.
##   * Curses scale rewards: clearing a run with N curses awards bonus meta
##     currency. That bonus is computed by `reward_multiplier()`.
##
## Gameplay reads the active set with `active_curses()`. Effects are encoded
## as a flat Dictionary of stat deltas + flags; the player controller / weapon
## / room logic just queries those keys.

signal curse_applied(id: String)
signal curse_cleared(id: String)
signal curses_reset()

const CATALOG := {
	"glass_cannon": {
		"title": "Glass Cannon",
		"desc": "+50% damage. -50% max HP.",
		"effects": {"damage_mult": 1.5, "max_hp_mult": 0.5},
		"weight": 4,
	},
	"slow_reload": {
		"title": "Heavy Action",
		"desc": "+30% damage. Reloads take twice as long.",
		"effects": {"damage_mult": 1.3, "reload_mult": 2.0},
		"weight": 5,
	},
	"one_shot": {
		"title": "One in the Chamber",
		"desc": "Magazine size is 1. Damage tripled.",
		"effects": {"mag_size_override": 1, "damage_mult": 3.0},
		"weight": 2,
	},
	"thin_skin": {
		"title": "Thin Skin",
		"desc": "+25% currency drops. Lose all i-frames on dodge.",
		"effects": {"currency_mult": 1.25, "dodge_iframes_mult": 0.0},
		"weight": 4,
	},
	"slow_motion": {
		"title": "Heavy Boots",
		"desc": "Movement speed -30%. +25% crit chance.",
		"effects": {"move_speed_mult": 0.7, "crit_chance_add": 0.25},
		"weight": 4,
	},
	"vengeful": {
		"title": "Vengeful",
		"desc": "Enemies hit harder. They also drop more currency.",
		"effects": {"enemy_damage_mult": 1.3, "currency_mult": 1.4},
		"weight": 4,
	},
	"berserker": {
		"title": "Berserker",
		"desc": "Damage scales up to 2x as HP drops to 0.",
		"effects": {"flag_berserker": true},
		"weight": 3,
	},
	"shadow_step": {
		"title": "Shadow Step",
		"desc": "Cannot be seen by enemies at range. No minimap.",
		"effects": {"flag_no_minimap": true, "enemy_sight_range_mult": 0.5},
		"weight": 3,
	},
	"echo_chamber": {
		"title": "Echo Chamber",
		"desc": "Every shot fires a delayed echo. -25% fire rate.",
		"effects": {"flag_echo_shots": true, "fire_rate_mult": 0.75},
		"weight": 3,
	},
	"hex_eater": {
		"title": "Hex Eater",
		"desc": "Curses on the gun are 50% stronger and 50% weaker downside.",
		"effects": {"flag_hex_eater": true},
		"weight": 2,
	},
}

const SAVE_PATH := "user://timeshot_curses.json"
const VERSION := 1

## Per-curse reward bonus. Three curses ~= 1.6x meta on clear.
const REWARD_BONUS_PER_CURSE := 0.2

var active: Array[String] = []  # ids currently applied for the upcoming/in-progress run


func _ready() -> void:
	_load()


## Roll N distinct curse options for the altar UI to choose from.
func roll_offer(n: int = 3, rng: RandomNumberGenerator = null) -> Array[String]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	# Weighted draw without replacement, ignoring curses already active.
	var pool: Array = []
	for id in CATALOG.keys():
		if id in active:
			continue
		var weight := int(CATALOG[id].get("weight", 1))
		for _i in range(weight):
			pool.append(id)
	var out: Array[String] = []
	while out.size() < n and not pool.is_empty():
		var idx := rng.randi() % pool.size()
		var pick := String(pool[idx])
		out.append(pick)
		# Drop every copy of this id.
		var filtered: Array = []
		for p in pool:
			if String(p) != pick:
				filtered.append(p)
		pool = filtered
	return out


func apply(id: String) -> bool:
	if not CATALOG.has(id):
		push_warning("CursePool: unknown curse %s" % id)
		return false
	if id in active:
		return false
	active.append(id)
	emit_signal("curse_applied", id)
	_save()
	return true


func clear(id: String) -> bool:
	if not id in active:
		return false
	active.erase(id)
	emit_signal("curse_cleared", id)
	_save()
	return true


func reset() -> void:
	active.clear()
	emit_signal("curses_reset")
	_save()


func active_curses() -> Array[String]:
	return active.duplicate()


## Returns the combined effects dictionary. Multiplicative keys (ending in
## _mult) are multiplied together; additive keys (_add) are summed; flags
## (flag_*) are OR'd. Override keys (_override) take the last writer wins.
func combined_effects() -> Dictionary:
	var out: Dictionary = {}
	for id in active:
		var eff: Dictionary = CATALOG.get(id, {}).get("effects", {})
		for k in eff.keys():
			var key := String(k)
			var v: Variant = eff[k]
			if key.ends_with("_mult"):
				out[key] = float(out.get(key, 1.0)) * float(v)
			elif key.ends_with("_add"):
				out[key] = float(out.get(key, 0.0)) + float(v)
			elif key.begins_with("flag_"):
				out[key] = bool(out.get(key, false)) or bool(v)
			else:
				out[key] = v
	return out


## Hex Eater modifies its own combined-effects sibling values. Apply this on
## top of combined_effects() if "flag_hex_eater" is set.
func apply_hex_eater(effects: Dictionary) -> Dictionary:
	if not bool(effects.get("flag_hex_eater", false)):
		return effects
	var out := effects.duplicate()
	for k in out.keys():
		var key := String(k)
		if not key.ends_with("_mult"):
			continue
		var v := float(out[k])
		# Boost favorable mults (>1) and soften unfavorable ones (<1).
		if v > 1.0:
			out[k] = 1.0 + (v - 1.0) * 1.5
		elif v < 1.0:
			out[k] = 1.0 - (1.0 - v) * 0.5
	return out


func reward_multiplier() -> float:
	return 1.0 + REWARD_BONUS_PER_CURSE * float(active.size())


func display_title(id: String) -> String:
	return String(CATALOG.get(id, {}).get("title", id))


func display_desc(id: String) -> String:
	return String(CATALOG.get(id, {}).get("desc", ""))


## --- Persistence ---

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("CursePool: cannot write save")
		return
	var data := {
		"version": VERSION,
		"active": active,
	}
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
	var a: Variant = (parsed as Dictionary).get("active", [])
	if a is Array:
		active.clear()
		for s in a:
			active.append(String(s))
