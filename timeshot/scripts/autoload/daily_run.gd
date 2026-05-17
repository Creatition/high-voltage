extends Node
## Daily seeded run: one deterministic challenge per calendar day (UTC).
##
## Not yet registered as an autoload — add `DailyRun="*res://scripts/autoload/daily_run.gd"`
## under [autoload] in project.godot when wiring it in.
##
## On boot, this computes today's seed and a fixed roster of era order +
## starting modifier from that seed. Players can only submit ONE attempt per
## day; subsequent attempts are flagged so leaderboards (whenever those land)
## can reject them. The seed is also exposed so dungeon_generator.gd can use
## the same RNG stream and produce the same layout for every player.

signal daily_started(date: String, seed: int)
signal daily_completed(date: String, victory: bool, score: int, duration_sec: float)

const SAVE_PATH := "user://timeshot_daily.json"
const VERSION := 1

const ERA_IDS: Array[String] = ["prehistoric", "egypt", "west", "future"]
const STARTING_MODIFIERS: Array[String] = [
	"glass_cannon",       # +50% damage, -50% max HP
	"speedrun",           # +20% move speed, room timer scoring
	"one_gun",            # cannot pick up upgrades; flat damage scaling
	"frugal",             # shops 50% off but you start with no currency
	"vampire",            # +lifesteal but currency drops halved
	"sniper",             # +crit chance but reduced fire rate
	"berserker",          # damage scales with missing HP
]

var current_date: String = ""
var current_seed: int = 0
var era_order: Array[String] = []
var modifier_id: String = ""

var attempted_today := false
var completed_today := false
var best_score := 0
var best_time_sec := 0.0
var history: Array = []  # last 30 days of {date, score, duration_sec, victory}


func _ready() -> void:
	_load()
	_refresh_for_today()


## Recompute today's daily — call this if the player keeps the game open past
## midnight UTC. Cheap; no-op if the date hasn't rolled over.
func _refresh_for_today() -> void:
	var today := _utc_date_string()
	if today == current_date and current_seed != 0:
		return
	current_date = today
	current_seed = _seed_from_date(today)
	var rng := RandomNumberGenerator.new()
	rng.seed = current_seed
	era_order = _shuffled(ERA_IDS.duplicate(), rng)
	modifier_id = STARTING_MODIFIERS[rng.randi() % STARTING_MODIFIERS.size()]
	# Reset per-day attempt flags if the date rolled over.
	if not _today_in_history():
		attempted_today = false
		completed_today = false
	_save()


func can_play() -> bool:
	_refresh_for_today()
	return not completed_today


## Call when player presses "Start Daily" from the menu. Returns the seed so
## the dungeon generator can seed itself with the same value.
func start_attempt() -> int:
	_refresh_for_today()
	attempted_today = true
	_save()
	emit_signal("daily_started", current_date, current_seed)
	return current_seed


## Call from the run-end flow with the final score + duration.
func submit_result(victory: bool, score: int, duration_sec: float) -> void:
	_refresh_for_today()
	completed_today = true
	if score > best_score:
		best_score = score
	if victory and (best_time_sec <= 0.0 or duration_sec < best_time_sec):
		best_time_sec = duration_sec
	history.append({
		"date": current_date,
		"victory": victory,
		"score": score,
		"duration_sec": duration_sec,
	})
	# Keep at most 30 entries.
	while history.size() > 30:
		history.pop_front()
	_save()
	emit_signal("daily_completed", current_date, victory, score, duration_sec)


func summary() -> Dictionary:
	_refresh_for_today()
	return {
		"date": current_date,
		"seed": current_seed,
		"era_order": era_order.duplicate(),
		"modifier_id": modifier_id,
		"attempted": attempted_today,
		"completed": completed_today,
		"best_score": best_score,
		"best_time_sec": best_time_sec,
	}


func streak_days() -> int:
	# Consecutive days ending today with a victory.
	if history.is_empty():
		return 0
	var streak := 0
	var i := history.size() - 1
	while i >= 0:
		var entry: Dictionary = history[i]
		if not bool(entry.get("victory", false)):
			break
		streak += 1
		i -= 1
	return streak


## --- Helpers ---

func _utc_date_string() -> String:
	# YYYY-MM-DD in UTC.
	var d := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


func _seed_from_date(date: String) -> int:
	# Stable 63-bit seed from the date string. Same algorithm everyone runs,
	# so two players on the same calendar day get the same dungeon.
	var h: int = 1469598103934665603
	for ch in date:
		h = (h ^ int(ch.unicode_at(0))) * 1099511628211
		h = h & 0x7FFFFFFFFFFFFFFF
	# Avoid 0 — RandomNumberGenerator treats 0 as "use time".
	if h == 0:
		h = 1
	return h


func _shuffled(arr: Array, rng: RandomNumberGenerator) -> Array[String]:
	var copy: Array = arr.duplicate()
	var n := copy.size()
	for i in range(n - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	var out: Array[String] = []
	for s in copy:
		out.append(String(s))
	return out


func _today_in_history() -> bool:
	for entry in history:
		if entry is Dictionary and String(entry.get("date", "")) == current_date:
			return true
	return false


## --- Persistence ---

func _save() -> void:
	var data := {
		"version": VERSION,
		"current_date": current_date,
		"attempted_today": attempted_today,
		"completed_today": completed_today,
		"best_score": best_score,
		"best_time_sec": best_time_sec,
		"history": history,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("DailyRun: cannot write save")
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
	current_date = String(data.get("current_date", ""))
	attempted_today = bool(data.get("attempted_today", false))
	completed_today = bool(data.get("completed_today", false))
	best_score = int(data.get("best_score", 0))
	best_time_sec = float(data.get("best_time_sec", 0.0))
	var h: Variant = data.get("history", [])
	if h is Array:
		history = (h as Array).duplicate()
