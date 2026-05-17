extends Node
## Global game state. Persists across scene changes.
## Holds run-specific data (current era, currency, active upgrades) and
## meta-progression data (permanent player upgrades, unlocked characters).

# --- Run state (resets each run) ---
var current_era: String = "present"
var run_currency: int = 0
var run_upgrades: Array[String] = []      # ids of upgrades equipped on the Chrono-Pistol this run
var current_character_id: String = "cas"

# Dungeon flow: GameState owns the queue of room scenes for the current era.
# Doors call next_room_path() when their next_scene_path is empty.
var dungeon_queue: Array[String] = []
var dungeon_index: int = 0

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


func add_currency(amount: int) -> void:
	run_currency += amount
	currency_changed.emit(run_currency)


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
	run_ended.emit(reason)


func reset_run() -> void:
	run_currency = 0
	run_upgrades.clear()
	dungeon_queue.clear()
	dungeon_index = 0
	current_era = "present"


# --- Dungeon flow ---

func start_era(era_id: String, room_paths: Array) -> void:
	current_era = era_id
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
