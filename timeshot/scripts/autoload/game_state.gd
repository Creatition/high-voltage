extends Node
## Global game state. Persists across scene changes.
## Holds run-specific data (current era, currency, active upgrades) and
## meta-progression data (permanent player upgrades, unlocked characters).

# --- Run state (resets each run) ---
var current_era: String = "present"
var run_currency: int = 0
var run_upgrades: Array[String] = []      # ids of upgrades equipped on the Chrono-Pistol this run
var current_character_id: String = "cas"

# --- Character level (Day 23) ---
# Enemies grant XP on death; hitting xp_to_next bumps the level and opens
# the upgrade picker. Resets to 1 on end_run().
var run_level: int = 1
var run_xp: int = 0
var run_xp_to_next: int = 26
# Day-28 balance: doubled the XP curve so a run sees ~3-4 picks instead of ~8-10.
# Players reported upgrade stacks were "way too powerful" by mid-run; the fix
# is fewer picks, not per-pick nerfs, so individual upgrades still feel impactful.
const XP_CURVE_BASE: int = 26
const XP_CURVE_PER_LEVEL: int = 14  # next-level cost grows linearly per level

# Dungeon flow: GameState owns the queue of room scenes for the current era.
# Doors call next_room_path() when their next_scene_path is empty.
var dungeon_queue: Array[String] = []
var dungeon_index: int = 0

# Run progression: the player picks one of two random eras, eras_per_run times.
const ERAS_PER_RUN: int = 5
var eras_picked: Array[String] = []           # ids in the order they were chosen
var eras_completed: Array[String] = []        # ids whose final boss has been killed

# --- Snapshots that survive end_run() so the post-run screen can show them ---
var last_run_upgrades: Array[String] = []
var last_run_currency: int = 0
var last_run_reason: String = ""

# --- Meta-progression (persists across runs) ---
var meta_currency: int = 0
var unlocked_characters: Array[String] = ["cas"]
var permanent_upgrades: Dictionary = {
	"max_hp_bonus": 0,
	"dodge_iframe_bonus": 0.0,
	"starting_reroll_tokens": 0,
}

# --- Signals ---
signal currency_changed(new_amount: int)
signal upgrade_added(upgrade_id: String)
signal run_ended(reason: String)
signal era_changed(new_era: String)
## XP changed (current_xp, xp_to_next, level). Fired whenever XP is granted.
signal xp_changed(current: int, to_next: int, level: int)
## Player crossed a level threshold. The HUD/UpgradeRouter listens and opens
## the picker; one signal per level so a single big XP grant can stack picks.
signal leveled_up(new_level: int)


func add_currency(amount: int) -> void:
	run_currency += amount
	currency_changed.emit(run_currency)


## Grants XP. Handles the case where a single grant crosses multiple level
## thresholds by emitting `leveled_up` once per level gained.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	run_xp += amount
	var levels_gained: int = 0
	while run_xp >= run_xp_to_next:
		run_xp -= run_xp_to_next
		run_level += 1
		run_xp_to_next = XP_CURVE_BASE + XP_CURVE_PER_LEVEL * (run_level - 1)
		levels_gained += 1
	xp_changed.emit(run_xp, run_xp_to_next, run_level)
	for _i in levels_gained:
		leveled_up.emit(run_level)


func _reset_level() -> void:
	run_level = 1
	run_xp = 0
	run_xp_to_next = XP_CURVE_BASE


func spend_currency(amount: int) -> bool:
	if run_currency < amount:
		return false
	run_currency -= amount
	currency_changed.emit(run_currency)
	return true


func add_run_upgrade(upgrade_id: String) -> void:
	run_upgrades.append(upgrade_id)
	upgrade_added.emit(upgrade_id)


func end_run(reason: String) -> void:
	# Snapshot first so the run-end screen can read what happened.
	last_run_upgrades = run_upgrades.duplicate()
	last_run_currency = run_currency
	last_run_reason = reason
	# Cash banked from this run rolls into meta currency on death/victory.
	meta_currency += run_currency
	run_currency = 0
	run_upgrades.clear()
	dungeon_queue.clear()
	dungeon_index = 0
	eras_picked.clear()
	eras_completed.clear()
	_reset_level()
	xp_changed.emit(run_xp, run_xp_to_next, run_level)
	run_ended.emit(reason)


func reset_run() -> void:
	run_currency = 0
	run_upgrades.clear()
	dungeon_queue.clear()
	dungeon_index = 0
	eras_picked.clear()
	eras_completed.clear()
	current_era = "present"
	_reset_level()
	xp_changed.emit(run_xp, run_xp_to_next, run_level)


func mark_era_complete(era_id: String) -> void:
	if era_id != "" and era_id not in eras_completed:
		eras_completed.append(era_id)


func picks_remaining() -> int:
	return maxi(0, ERAS_PER_RUN - eras_picked.size())


func is_run_complete() -> bool:
	return eras_picked.size() >= ERAS_PER_RUN


# --- Dungeon flow ---

func start_era(era_id: String, room_paths: Array) -> void:
	current_era = era_id
	if era_id != "" and era_id not in eras_picked:
		eras_picked.append(era_id)
	dungeon_queue.clear()
	for p in room_paths:
		dungeon_queue.append(String(p))
	dungeon_index = 0
	era_changed.emit(era_id)


func current_room_path() -> String:
	if dungeon_index < dungeon_queue.size():
		return dungeon_queue[dungeon_index]
	return ""


func next_room_path() -> String:
	dungeon_index += 1
	return current_room_path()
