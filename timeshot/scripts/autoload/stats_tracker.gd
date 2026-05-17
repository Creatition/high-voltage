extends Node
## Per-run and lifetime statistics tracker.
##
## Not yet registered as an autoload — add `StatsTracker="*res://scripts/autoload/stats_tracker.gd"`
## under [autoload] in project.godot when ready to wire it into gameplay.
##
## Per-run counters reset on `begin_run()`. Lifetime counters are merged in on
## `end_run()` and persisted to disk. The class is intentionally dumb — gameplay
## code calls `note_kill`, `note_damage_taken`, etc., and this just adds.
##
## The summary returned by `current_run_summary()` is what the run-end screen
## should render. The summary returned by `lifetime_summary()` is what a
## "career" page would render.

const SAVE_PATH := "user://timeshot_stats.json"
const VERSION := 1

var run: Dictionary = _fresh_run()
var lifetime: Dictionary = _fresh_lifetime()
var _run_active := false
var _run_started_at_msec: int = 0


func _ready() -> void:
	_load()


## --- Run lifecycle ---

func begin_run(character_id: String = "", era_id: String = "") -> void:
	run = _fresh_run()
	run["character_id"] = character_id
	run["era_id"] = era_id
	run["started_at"] = Time.get_datetime_string_from_system()
	_run_started_at_msec = Time.get_ticks_msec()
	_run_active = true


func end_run(victory: bool, reason: String = "") -> void:
	if not _run_active:
		return
	_run_active = false
	run["duration_sec"] = (Time.get_ticks_msec() - _run_started_at_msec) / 1000.0
	run["victory"] = victory
	run["reason"] = reason

	lifetime["runs"] = int(lifetime.get("runs", 0)) + 1
	if victory:
		lifetime["victories"] = int(lifetime.get("victories", 0)) + 1
	else:
		lifetime["deaths"] = int(lifetime.get("deaths", 0)) + 1

	# Roll up cumulative counters.
	for key in [
		"kills", "boss_kills", "damage_dealt", "damage_taken", "shots_fired",
		"shots_hit", "secret_rooms_found", "rooms_cleared", "upgrades_taken",
		"currency_earned", "items_purchased",
	]:
		lifetime[key] = int(lifetime.get(key, 0)) + int(run.get(key, 0))

	# Personal bests.
	var dur := float(run["duration_sec"])
	if victory:
		var best := float(lifetime.get("fastest_clear_sec", 0.0))
		if best <= 0.0 or dur < best:
			lifetime["fastest_clear_sec"] = dur
	var longest := float(lifetime.get("longest_run_sec", 0.0))
	if dur > longest:
		lifetime["longest_run_sec"] = dur

	var best_kills := int(lifetime.get("most_kills_run", 0))
	if int(run.get("kills", 0)) > best_kills:
		lifetime["most_kills_run"] = int(run["kills"])

	_save()


## --- Counters (called from gameplay) ---

func note_kill(is_boss: bool = false) -> void:
	run["kills"] = int(run.get("kills", 0)) + 1
	if is_boss:
		run["boss_kills"] = int(run.get("boss_kills", 0)) + 1


func note_damage_dealt(amount: float) -> void:
	run["damage_dealt"] = float(run.get("damage_dealt", 0.0)) + amount


func note_damage_taken(amount: float) -> void:
	run["damage_taken"] = float(run.get("damage_taken", 0.0)) + amount


func note_shot_fired() -> void:
	run["shots_fired"] = int(run.get("shots_fired", 0)) + 1


func note_shot_hit() -> void:
	run["shots_hit"] = int(run.get("shots_hit", 0)) + 1


func note_secret_room() -> void:
	run["secret_rooms_found"] = int(run.get("secret_rooms_found", 0)) + 1


func note_room_cleared() -> void:
	run["rooms_cleared"] = int(run.get("rooms_cleared", 0)) + 1


func note_upgrade_taken() -> void:
	run["upgrades_taken"] = int(run.get("upgrades_taken", 0)) + 1


func note_currency(amount: int) -> void:
	run["currency_earned"] = int(run.get("currency_earned", 0)) + amount


func note_purchase() -> void:
	run["items_purchased"] = int(run.get("items_purchased", 0)) + 1


## --- Readouts ---

func current_run_summary() -> Dictionary:
	var fired := int(run.get("shots_fired", 0))
	var hit := int(run.get("shots_hit", 0))
	var acc := 0.0 if fired == 0 else float(hit) / float(fired)
	return {
		"kills": int(run.get("kills", 0)),
		"boss_kills": int(run.get("boss_kills", 0)),
		"damage_dealt": float(run.get("damage_dealt", 0.0)),
		"damage_taken": float(run.get("damage_taken", 0.0)),
		"accuracy": acc,
		"rooms_cleared": int(run.get("rooms_cleared", 0)),
		"secret_rooms_found": int(run.get("secret_rooms_found", 0)),
		"upgrades_taken": int(run.get("upgrades_taken", 0)),
		"currency_earned": int(run.get("currency_earned", 0)),
		"duration_sec": float(run.get("duration_sec", (Time.get_ticks_msec() - _run_started_at_msec) / 1000.0)) if _run_active else float(run.get("duration_sec", 0.0)),
	}


func lifetime_summary() -> Dictionary:
	var fired := int(lifetime.get("shots_fired", 0))
	var hit := int(lifetime.get("shots_hit", 0))
	var acc := 0.0 if fired == 0 else float(hit) / float(fired)
	var s := lifetime.duplicate()
	s["accuracy"] = acc
	return s


## --- Persistence ---

func _fresh_run() -> Dictionary:
	return {
		"character_id": "",
		"era_id": "",
		"started_at": "",
		"duration_sec": 0.0,
		"victory": false,
		"reason": "",
		"kills": 0,
		"boss_kills": 0,
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"shots_fired": 0,
		"shots_hit": 0,
		"secret_rooms_found": 0,
		"rooms_cleared": 0,
		"upgrades_taken": 0,
		"currency_earned": 0,
		"items_purchased": 0,
	}


func _fresh_lifetime() -> Dictionary:
	return {
		"version": VERSION,
		"runs": 0,
		"victories": 0,
		"deaths": 0,
		"kills": 0,
		"boss_kills": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"shots_fired": 0,
		"shots_hit": 0,
		"secret_rooms_found": 0,
		"rooms_cleared": 0,
		"upgrades_taken": 0,
		"currency_earned": 0,
		"items_purchased": 0,
		"fastest_clear_sec": 0.0,
		"longest_run_sec": 0.0,
		"most_kills_run": 0,
	}


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("StatsTracker: cannot write save")
		return
	f.store_string(JSON.stringify(lifetime))
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
	for k in (parsed as Dictionary).keys():
		lifetime[String(k)] = (parsed as Dictionary)[k]
