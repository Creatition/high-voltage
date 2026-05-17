extends Control
class_name MetaMenu
## Between-run "Time Bank." Spend meta_currency on permanent upgrades
## and character unlocks. Saves immediately after each purchase.

const PERM_UPGRADES := [
	{
		"key": "max_hp_bonus",
		"name": "Reinforced Frame",
		"description": "+1 max HP on every run.",
		"cost": 150,
		"step": 1,
		"max": 5,
		"is_int": true,
	},
	{
		"key": "dodge_iframe_bonus",
		"name": "Smooth Roll",
		"description": "+0.05s of iframes on every dodge.",
		"cost": 120,
		"step": 0.05,
		"max": 0.25,
		"is_int": false,
	},
	{
		"key": "starting_reroll_tokens",
		"name": "Lucky Coin",
		"description": "+1 free shrine re-roll token per run.",
		"cost": 100,
		"step": 1,
		"max": 3,
		"is_int": true,
	},
]

@onready var _currency: Label = $Margin/Root/Header/Currency
@onready var _list: VBoxContainer = $Margin/Root/Scroll/List
@onready var _back: Button = $Margin/Root/Footer/Back


func _ready() -> void:
	_back.pressed.connect(_on_back)
	_refresh()


func _refresh() -> void:
	_currency.text = "$ %d banked" % GameState.meta_currency
	for c in _list.get_children():
		c.queue_free()
	for u in PERM_UPGRADES:
		_list.add_child(_make_perm_card(u))
	for character in CharacterRegistry.characters:
		if int(character.get("unlock_cost", 0)) > 0:
			_list.add_child(_make_char_card(character))


func _make_perm_card(u: Dictionary) -> Control:
	var current: Variant = GameState.permanent_upgrades.get(u["key"], 0)
	var u_max: Variant = u["max"]
	var maxed: bool = current >= u_max
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 70)
	row.add_theme_constant_override("separation", 16)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = "%s  (now: %s)" % [u["name"], str(current)]
	name_lbl.add_theme_font_size_override("font_size", 18)
	body.add_child(name_lbl)
	var desc := Label.new()
	desc.text = u["description"]
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	body.add_child(desc)
	row.add_child(body)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 56)
	if maxed:
		btn.text = "MAXED"
		btn.disabled = true
	else:
		btn.text = "Buy  $ %d" % u["cost"]
		btn.disabled = GameState.meta_currency < int(u["cost"])
		btn.pressed.connect(_on_buy_perm.bind(u))
	row.add_child(btn)
	return row


func _make_char_card(c: Dictionary) -> Control:
	var unlocked := CharacterRegistry.is_unlocked(c["id"])
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 70)
	row.add_theme_constant_override("separation", 16)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = c["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", c.get("color", Color.WHITE))
	body.add_child(name_lbl)
	var desc := Label.new()
	desc.text = c["blurb"]
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	body.add_child(desc)
	row.add_child(body)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 56)
	if unlocked:
		btn.text = "UNLOCKED"
		btn.disabled = true
	else:
		btn.text = "Unlock  $ %d" % int(c["unlock_cost"])
		btn.disabled = GameState.meta_currency < int(c["unlock_cost"])
		btn.pressed.connect(_on_unlock_char.bind(c))
	row.add_child(btn)
	return row


func _on_buy_perm(u: Dictionary) -> void:
	var cost := int(u["cost"])
	if GameState.meta_currency < cost:
		return
	GameState.meta_currency -= cost
	if u["is_int"]:
		GameState.permanent_upgrades[u["key"]] = int(GameState.permanent_upgrades.get(u["key"], 0)) + int(u["step"])
	else:
		GameState.permanent_upgrades[u["key"]] = float(GameState.permanent_upgrades.get(u["key"], 0.0)) + float(u["step"])
	SaveSystem.save()
	_refresh()


func _on_unlock_char(c: Dictionary) -> void:
	var cost := int(c["unlock_cost"])
	if GameState.meta_currency < cost:
		return
	GameState.meta_currency -= cost
	SaveSystem.unlock_character(c["id"])
	SaveSystem.save()
	_refresh()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
