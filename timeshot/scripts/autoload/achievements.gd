extends Node
## Achievement registry + unlock tracker.
##
## Not registered as an autoload yet — drop this into project.godot under
## [autoload] as `Achievements="*res://scripts/autoload/achievements.gd"` when
## wiring it up. Keeping it standalone for now so existing scenes don't break.
##
## Achievements are pure metadata: an id, a human title, a short description, a
## hidden flag (spoiler achievements stay masked until unlocked), and an
## optional meta_currency reward paid out on first unlock.
##
## Other systems call `Achievements.unlock(id)` at the appropriate moment.
## The class also exposes thin helpers like `track_kill`, `track_run_clear`,
## and `track_secret_room_found` so callers don't have to know the id strings.

signal achievement_unlocked(id: String, def: Dictionary)
signal progress_changed(id: String, current: int, total: int)

const SAVE_PATH := "user://timeshot_achievements.json"
const VERSION := 1

## Static catalog. Order in this dict is the display order in any future UI.
const CATALOG := {
	"first_blood": {
		"title": "First Blood",
		"desc": "Defeat your first enemy.",
		"hidden": false,
		"reward": 5,
	},
	"present_clear": {
		"title": "Out of the Garage",
		"desc": "Clear the Present Day tutorial era.",
		"hidden": false,
		"reward": 25,
	},
	"prehistoric_clear": {
		"title": "Apex Predator",
		"desc": "Down the Prehistoric boss.",
		"hidden": false,
		"reward": 50,
	},
	"egypt_clear": {
		"title": "Pharaoh's Bane",
		"desc": "Crack open the Pyramid.",
		"hidden": false,
		"reward": 50,
	},
	"west_clear": {
		"title": "Faster Draw",
		"desc": "Outshoot the Wild West outlaw.",
		"hidden": false,
		"reward": 50,
	},
	"future_clear": {
		"title": "Disconnected",
		"desc": "Bring down the AI Core.",
		"hidden": false,
		"reward": 50,
	},
	"corrupted_clear": {
		"title": "Loop Closed",
		"desc": "Defeat the final boss in the Corrupted Present.",
		"hidden": false,
		"reward": 200,
	},
	"no_hit_boss": {
		"title": "Untouchable",
		"desc": "Defeat any era boss without taking damage.",
		"hidden": false,
		"reward": 100,
	},
	"secret_seeker": {
		"title": "Secret Seeker",
		"desc": "Discover 10 secret rooms across all runs.",
		"hidden": false,
		"reward": 50,
		"goal": 10,
	},
	"hoarder": {
		"title": "Time Hoarder",
		"desc": "Bank 1000 lifetime meta-currency.",
		"hidden": false,
		"reward": 25,
		"goal": 1000,
	},
	"speedrunner": {
		"title": "Tachyon",
		"desc": "Clear any era in under 3 minutes.",
		"hidden": false,
		"reward": 75,
	},
	"the_collector": {
		"title": "The Collector",
		"desc": "Stack 5 gun upgrades in a single run.",
		"hidden": false,
		"reward": 50,
	},
	"forgive_them": {
		"title": "Forgive Them",
		"desc": "...you'll know when.",
		"hidden": true,
		"reward": 100,
	},
}

var _unlocked: Dictionary = {}      # id -> ISO timestamp
var _progress: Dictionary = {}      # id -> int (for goal-based achievements)


func _ready() -> void:
	_load()


func is_unlocked(id: String) -> bool:
	return _unlocked.has(id)


func unlock(id: String) -> bool:
	if not CATALOG.has(id):
		push_warning("Achievements: unknown id %s" % id)
		return false
	if _unlocked.has(id):
		return false
	_unlocked[id] = Time.get_datetime_string_from_system()
	var def: Dictionary = CATALOG[id]
	var reward := int(def.get("reward", 0))
	if reward > 0:
		var gs := get_node_or_null("/root/GameState")
		if gs != null and "meta_currency" in gs:
			gs.meta_currency += reward
	emit_signal("achievement_unlocked", id, def)
	_save()
	return true


func add_progress(id: String, amount: int = 1) -> void:
	if not CATALOG.has(id):
		return
	if _unlocked.has(id):
		return
	var def: Dictionary = CATALOG[id]
	var goal := int(def.get("goal", 0))
	if goal <= 0:
		return
	var current := int(_progress.get(id, 0)) + amount
	_progress[id] = current
	emit_signal("progress_changed", id, current, goal)
	if current >= goal:
		unlock(id)
	else:
		_save()


## --- Convenience hooks called from gameplay code ---

func track_kill() -> void:
	unlock("first_blood")


func track_era_clear(era_id: String) -> void:
	var id := "%s_clear" % era_id.to_lower()
	unlock(id)


func track_run_clear() -> void:
	unlock("corrupted_clear")


func track_no_hit_boss() -> void:
	unlock("no_hit_boss")


func track_secret_room_found() -> void:
	add_progress("secret_seeker", 1)


func track_meta_currency_total(total: int) -> void:
	# total is lifetime, not delta — store as current progress directly.
	if _unlocked.has("hoarder"):
		return
	_progress["hoarder"] = total
	emit_signal("progress_changed", "hoarder", total, int(CATALOG["hoarder"]["goal"]))
	if total >= int(CATALOG["hoarder"]["goal"]):
		unlock("hoarder")
	else:
		_save()


func track_speed_clear(seconds: float) -> void:
	if seconds <= 180.0:
		unlock("speedrunner")


func track_upgrade_count(count: int) -> void:
	if count >= 5:
		unlock("the_collector")


func get_progress(id: String) -> Vector2i:
	var def: Dictionary = CATALOG.get(id, {})
	var goal := int(def.get("goal", 0))
	var cur := int(_progress.get(id, 0))
	return Vector2i(cur, goal)


func display_title(id: String) -> String:
	var def: Dictionary = CATALOG.get(id, {})
	if def.get("hidden", false) and not _unlocked.has(id):
		return "???"
	return String(def.get("title", id))


func display_desc(id: String) -> String:
	var def: Dictionary = CATALOG.get(id, {})
	if def.get("hidden", false) and not _unlocked.has(id):
		return "Hidden achievement."
	return String(def.get("desc", ""))


func unlocked_count() -> int:
	return _unlocked.size()


func total_count() -> int:
	return CATALOG.size()


## --- Persistence ---

func _save() -> void:
	var data := {
		"version": VERSION,
		"unlocked": _unlocked,
		"progress": _progress,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Achievements: cannot write save")
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
	var u: Variant = data.get("unlocked", {})
	if u is Dictionary:
		_unlocked = (u as Dictionary).duplicate()
	var p: Variant = data.get("progress", {})
	if p is Dictionary:
		for k in (p as Dictionary).keys():
			_progress[String(k)] = int((p as Dictionary)[k])
