extends Control
class_name CharacterSelect
## Shown at the start of every new run. Pick which character to play; the
## chosen id is stashed in GameState.current_character_id and consumed by
## the player on spawn.

@onready var _row: HBoxContainer = $Center/VBox/Row
@onready var _back: Button = $Center/VBox/Footer/Back


func _ready() -> void:
	_back.pressed.connect(_on_back)
	_render()


func _render() -> void:
	for c in _row.get_children():
		c.queue_free()
	for character in CharacterRegistry.characters:
		_row.add_child(_make_card(character))


func _make_card(c: Dictionary) -> Control:
	var unlocked := CharacterRegistry.is_unlocked(c["id"])
	var card := Button.new()
	card.custom_minimum_size = Vector2(280, 360)
	card.disabled = not unlocked
	card.pressed.connect(_on_pick.bind(c["id"]))

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 14
	vbox.offset_top = 14
	vbox.offset_right = -14
	vbox.offset_bottom = -14
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 60)
	swatch.color = c.get("color", Color.WHITE)
	vbox.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text = c["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var blurb := Label.new()
	blurb.text = c["blurb"]
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.add_theme_font_size_override("font_size", 14)
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(blurb)

	var stats := c.get("stats", {})
	var stat_line := Label.new()
	stat_line.text = "HP %d  •  Spd %.0f" % [int(stats.get("max_hp", 5)), float(stats.get("move_speed", 220.0))]
	stat_line.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	stat_line.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stat_line)

	if not unlocked:
		var locked := Label.new()
		locked.text = "LOCKED ($%d in Time Bank)" % int(c.get("unlock_cost", 0))
		locked.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		vbox.add_child(locked)

	return card


func _on_pick(id: String) -> void:
	GameState.current_character_id = id
	get_tree().change_scene_to_file("res://scenes/ui/era_picker.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
