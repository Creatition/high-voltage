extends Node
## Registry of every era the player can travel to.
## Eras are data: an id, a display name, a color tint, a tag-line description,
## an unlocked flag, and a `room_queue` of res:// scene paths.
##
## Stub eras (the ones we haven't bespoke-themed yet) point at the existing
## Present rooms with a recoloured palette — enough surface variety for the
## prototype's 2-of-N era picker.

const PRESENT_ROOMS := [
	"res://scenes/rooms/present_room_01.tscn",
	"res://scenes/rooms/present_room_02.tscn",
	"res://scenes/rooms/present_boss.tscn",
]

var eras: Array = []   # Array[Dictionary]


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	eras.clear()
	# Present is the tutorial-ish "ordinary world" era — always available as
	# a seed option for the very first pick of a run.
	_add("present",      "Present",            "Cops, helicopters, and your apartment block.",       Color(0.55, 0.85, 1.00),  PRESENT_ROOMS,                    true,  true)
	_add("prehistoric",  "Prehistoric",        "Charging dinos and bleed traps.",                    Color(0.65, 0.85, 0.35),  PRESENT_ROOMS,                    true,  false)
	_add("egypt",        "Ancient Egypt",      "Curse-jammed guns, trap-heavy tombs.",               Color(0.95, 0.80, 0.30),  PRESENT_ROOMS,                    true,  false)
	_add("aztec",        "Aztec",              "Jade obsidian rituals. Watch the floor.",            Color(0.30, 0.85, 0.55),  _aztec_rooms(),                   true,  false)
	_add("medieval",     "Medieval",           "Plate, pikes, and a stubborn baron.",                Color(0.78, 0.70, 0.55),  PRESENT_ROOMS,                    true,  false)
	_add("feudal_japan", "Feudal Japan",       "Samurai parries and smoke-bomb ninjas.",             Color(0.95, 0.45, 0.50),  PRESENT_ROOMS,                    true,  false)
	_add("pirate",       "Pirate Age",         "Cutlasses, cannon traps, deck-rolling barrels.",     Color(0.85, 0.75, 0.45),  PRESENT_ROOMS,                    true,  false)
	_add("wild_west",    "Wild West",          "Quick-draw duels and dynamite.",                     Color(0.95, 0.55, 0.30),  PRESENT_ROOMS,                    true,  false)
	_add("cold_war",     "Cold War / 80s",     "Trenchcoat agents in neon arcades.",                 Color(0.40, 0.55, 0.95),  PRESENT_ROOMS,                    true,  false)
	_add("future",       "Future",             "Shielded enemies and EMP rooms.",                    Color(0.55, 0.95, 0.85),  PRESENT_ROOMS,                    true,  false)
	_add("alien",        "Alien Invasion",     "Furthest forward. Nothing here was built by humans.",Color(0.55, 1.00, 0.45),  _alien_rooms(),                   true,  false)


func _add(era_id: String, name: String, description: String, color: Color, room_queue: Array, unlocked: bool, is_seed: bool) -> void:
	eras.append({
		"id": era_id,
		"name": name,
		"description": description,
		"color": color,
		"room_queue": room_queue,
		"unlocked": unlocked,
		"is_seed": is_seed,
	})


func _aztec_rooms() -> Array:
	# Aztec scenes are built in Day 9; fall back to Present rooms if not present yet.
	var aztec_first := "res://scenes/rooms/aztec_room_01.tscn"
	if ResourceLoader.exists(aztec_first):
		return [
			aztec_first,
			"res://scenes/rooms/aztec_boss.tscn",
		]
	return PRESENT_ROOMS


func _alien_rooms() -> Array:
	# Alien scenes are built in Day 10; same fallback strategy.
	var first := "res://scenes/rooms/alien_room_01.tscn"
	if ResourceLoader.exists(first):
		return [
			first,
			"res://scenes/rooms/alien_boss.tscn",
		]
	return PRESENT_ROOMS


## Returns N era dicts at random from the available pool, excluding any
## already-completed eras.
func roll(count: int, exclude_ids: Array = [], seed_only: bool = false) -> Array:
	var pool: Array = []
	for era in eras:
		if not era.get("unlocked", false):
			continue
		if era.get("id") in exclude_ids:
			continue
		if seed_only and not era.get("is_seed", false):
			continue
		pool.append(era)
	# If seed_only produced too few, top up from any era.
	if seed_only and pool.size() < count:
		for era in eras:
			if era in pool:
				continue
			if era.get("id") in exclude_ids:
				continue
			pool.append(era)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


func get_by_id(era_id: String) -> Dictionary:
	for era in eras:
		if era.get("id") == era_id:
			return era
	return {}
