extends Node
## Persistent save: meta currency, unlocked characters, and permanent upgrades.
## Stored at user://timeshot_save.json as plain JSON.
##
## Loaded on _ready and merged into GameState. Saved on end_run() and any time
## an unlock/purchase happens via SaveSystem.save().

const SAVE_PATH := "user://timeshot_save.json"
const VERSION := 1

func _ready() -> void:
	load_save()
	# Also save whenever a run ends so banked currency persists.
	GameState.run_ended.connect(_on_run_ended)


func _on_run_ended(_reason: String) -> void:
	save()


func save() -> void:
	var data := {
		"version": VERSION,
		"meta_currency": GameState.meta_currency,
		"unlocked_characters": GameState.unlocked_characters.duplicate(),
		"permanent_upgrades": GameState.permanent_upgrades.duplicate(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: could not open save for write")
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	GameState.meta_currency = int(data.get("meta_currency", 0))
	var chars = data.get("unlocked_characters", ["cas"])
	if chars is Array:
		GameState.unlocked_characters.clear()
		for c in chars:
			GameState.unlocked_characters.append(String(c))
		if not "cas" in GameState.unlocked_characters:
			GameState.unlocked_characters.append("cas")
	var perms = data.get("permanent_upgrades", {})
	if perms is Dictionary:
		for k in perms.keys():
			GameState.permanent_upgrades[k] = perms[k]


## Spend meta_currency for a permanent unlock. Returns true on success.
func purchase_meta(cost: int, on_success: Callable) -> bool:
	if GameState.meta_currency < cost:
		return false
	GameState.meta_currency -= cost
	on_success.call()
	save()
	return true


func unlock_character(character_id: String) -> void:
	if character_id in GameState.unlocked_characters:
		return
	GameState.unlocked_characters.append(character_id)


func bump_permanent(key: String, delta) -> void:
	var current = GameState.permanent_upgrades.get(key, 0)
	if current is float or delta is float:
		GameState.permanent_upgrades[key] = float(current) + float(delta)
	else:
		GameState.permanent_upgrades[key] = int(current) + int(delta)
