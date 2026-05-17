extends Node
## Global game state. Persists across scene changes.
## Holds run-specific data (current era, currency, active upgrades) and
## meta-progression data (permanent player upgrades, unlocked characters).

# --- Run state (resets each run) ---
var current_era: String = "present"
var run_currency: int = 0
var run_upgrades: Array[String] = []      # ids of upgrades equipped on the Chrono-Pistol this run
var current_character_id: String = "cas"

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
	# Cash banked from this run rolls into meta currency on death/victory.
	meta_currency += run_currency
	run_currency = 0
	run_upgrades.clear()
	run_ended.emit(reason)


func reset_run() -> void:
	run_currency = 0
	run_upgrades.clear()
	current_era = "present"
