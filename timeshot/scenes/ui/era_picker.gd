extends Control
class_name EraPicker
## Full-screen "choose your next era" picker. Shows two random era cards
## drawn from EraRegistry and excludes eras already chosen this run.
##
## When the player clicks a card:
##   GameState.start_era(era_id, era.room_queue)
##   change_scene_to_file(first room of that era)
##
## After ERAS_PER_RUN picks have been completed (i.e., the player just killed
## the boss of the 5th era), this scene is the "victory" screen and the cards
## are replaced with a "Run Complete" message + return-to-menu button.

@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _row: HBoxContainer = $Center/VBox/Row
@onready var _victory_panel: VBoxContainer = $Center/VBox/VictoryPanel
@onready var _victory_button: Button = $Center/VBox/VictoryPanel/MenuBtn
@onready var _shop_button: Button = $Center/VBox/ShopBtn


func _ready() -> void:
	_victory_button.pressed.connect(_on_victory_menu)
	_shop_button.pressed.connect(_on_shop_pressed)
	if GameState.is_run_complete():
		_show_victory()
	else:
		_render_picker()
	# Day-28: focus first era card / victory button so gamepad works.
	call_deferred("_grab_first_focus")


func _grab_first_focus() -> void:
	if _victory_panel != null and _victory_panel.visible and _victory_button != null:
		_victory_button.grab_focus()
		return
	for c in _row.get_children():
		if c is Button:
			c.focus_mode = Control.FOCUS_ALL
			c.grab_focus()
			return


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rooms/shop_room.tscn")


func _render_picker() -> void:
	_victory_panel.visible = false
	var pick_number := GameState.eras_picked.size() + 1
	_title.text = "Choose Era %d of %d" % [pick_number, GameState.ERAS_PER_RUN]
	_subtitle.text = "Where does the time machine take you next?"

	for c in _row.get_children():
		c.queue_free()

	# First pick prefers "seed" eras (Present-ish). Later picks are wide open.
	var seed_only := GameState.eras_picked.is_empty()
	var options := EraRegistry.roll(2, GameState.eras_picked, seed_only)
	if options.size() < 2:
		# Pad with whatever is left so the player always has 2 cards.
		var pad := EraRegistry.roll(2, GameState.eras_picked, false)
		for era in pad:
			if era not in options:
				options.append(era)
				if options.size() >= 2:
					break

	for era in options:
		_row.add_child(_build_card(era))


func _build_card(era: Dictionary) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(360, 360)
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_on_era_picked.bind(era))

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 18
	vbox.offset_top = 18
	vbox.offset_right = -18
	vbox.offset_bottom = -18
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 60)
	swatch.color = era.get("color", Color.WHITE)
	vbox.add_child(swatch)

	var name_label := Label.new()
	name_label.text = era.get("name", era.get("id", "???"))
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var desc := Label.new()
	desc.text = era.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	var room_count := int(era.get("room_queue", []).size())
	var meta := Label.new()
	meta.text = "%d rooms" % room_count
	meta.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	meta.add_theme_font_size_override("font_size", 12)
	vbox.add_child(meta)

	return card


func _on_era_picked(era: Dictionary) -> void:
	var queue: Array = []
	for p in era.get("room_queue", []):
		queue.append(p)
	if queue.is_empty():
		return
	var era_id: String = String(era.get("id", ""))
	GameState.start_era(era_id, queue)
	# Day-27 fix: also kick off the procgen pipeline so the minimap has a
	# layout to draw. The legacy room queue still drives actual gameplay
	# (until each era's rooms migrate to DungeonRunner.advance_through),
	# but DungeonRunner.layout is now populated, which is what the
	# gungeon_minimap.gd in hud.tscn reads.
	var runner := get_node_or_null("/root/DungeonRunner")
	if runner != null and runner.has_method("start_generated_era"):
		# Deterministic seed per-era-per-pick so reloading shows the same
		# layout, but each new pick yields a fresh dungeon.
		var seed_value: int = (era_id.hash() ^ (GameState.eras_picked.size() * 7919)) & 0x7fffffff
		runner.start_generated_era(era_id, seed_value)
	get_tree().change_scene_to_file(queue[0])


func _show_victory() -> void:
	_title.text = "RUN COMPLETE"
	_subtitle.text = "You survived %d eras." % GameState.eras_picked.size()
	for c in _row.get_children():
		c.queue_free()
	_victory_panel.visible = true
	_shop_button.visible = false


func _on_victory_menu() -> void:
	GameState.end_run("victory")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
