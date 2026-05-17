extends Node
## Registry of selectable characters and their stat overrides.
## Each character is data — applied to the Player at run-start by
## player._apply_character_overrides() reading GameState.current_character_id.
##
## Schema:
##   id, name, blurb, color, unlock_cost (0 = free),
##   stats: { move_speed, max_hp, dodge_cooldown, shoot_cooldown }
##   starter_upgrade: optional upgrade id auto-added on run start (e.g. "shotgun_1")

var characters: Array = []


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	characters.clear()
	_add({
		"id": "cas",
		"name": "Cas",
		"blurb": "Reckless. Decent at everything.",
		"color": Color(1.0, 0.85, 0.30),
		"unlock_cost": 0,
		"stats": {
			"move_speed": 220.0,
			"max_hp": 5,
			"dodge_cooldown": 0.6,
			"shoot_cooldown": 0.18,
		},
		"starter_upgrade": "",
	})
	_add({
		"id": "maya",
		"name": "Maya the Engineer",
		"blurb": "Slower, sturdier. Starts with Boomstick.",
		"color": Color(0.70, 0.90, 1.0),
		"unlock_cost": 200,
		"stats": {
			"move_speed": 195.0,
			"max_hp": 7,
			"dodge_cooldown": 0.8,
			"shoot_cooldown": 0.22,
		},
		"starter_upgrade": "explosive_1",
	})
	_add({
		"id": "kai",
		"name": "Kai the Scout",
		"blurb": "Faster, fragile. Starts with Spread Shot.",
		"color": Color(0.50, 1.0, 0.55),
		"unlock_cost": 200,
		"stats": {
			"move_speed": 260.0,
			"max_hp": 4,
			"dodge_cooldown": 0.45,
			"shoot_cooldown": 0.15,
		},
		"starter_upgrade": "shotgun_1",
	})


func _add(data: Dictionary) -> void:
	characters.append(data)


func get_by_id(id: String) -> Dictionary:
	for c in characters:
		if c.get("id") == id:
			return c
	return {}


func is_unlocked(id: String) -> bool:
	return id in GameState.unlocked_characters
