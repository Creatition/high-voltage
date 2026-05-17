extends CanvasLayer
class_name UpgradePicker
## Modal upgrade selection screen, Hades/Slay-the-Spire style.
## Pauses the tree, shows 3 cards, applies the choice to GameState and resumes.
##
## Usage:
##   var picker := preload("res://scenes/ui/upgrade_picker.tscn").instantiate()
##   get_tree().current_scene.add_child(picker)
##   picker.open(era_name)
## or with a custom set of upgrades:
##   picker.open_with(upgrades: Array)

signal closed(picked_upgrade_id: String)

const CARD_SIZE := Vector2(280, 360)
## Day 23: rarity is shown via tinted card background + colored border so the
## player can recognize tier at a glance. EPIC and UNCOMMON joined the table.
const TIER_COLORS := {
	"common":    Color(0.82, 0.82, 0.88, 1.0),
	"uncommon":  Color(0.45, 0.95, 0.55, 1.0),
	"rare":      Color(0.40, 0.70, 1.00, 1.0),
	"epic":      Color(0.80, 0.45, 1.00, 1.0),
	"legendary": Color(1.00, 0.75, 0.30, 1.0),
}
const TIER_BG := {
	"common":    Color(0.16, 0.16, 0.20, 1.0),
	"uncommon":  Color(0.10, 0.20, 0.12, 1.0),
	"rare":      Color(0.10, 0.16, 0.26, 1.0),
	"epic":      Color(0.18, 0.10, 0.26, 1.0),
	"legendary": Color(0.24, 0.16, 0.06, 1.0),
}

@onready var _dim: ColorRect = $Dim
@onready var _row: HBoxContainer = $Center/Panel/Margin/Layout/Row
@onready var _title: Label = $Center/Panel/Margin/Layout/Title
@onready var _hint: Label = $Center/Panel/Margin/Layout/Hint
@onready var _reroll_btn: Button = $Center/Panel/Margin/Layout/RerollBtn

var _offered: Array = []
var _era: String = "any"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	visible = false


func open(era: String = "any") -> void:
	_era = era
	_offered = UpgradePool.roll(3, era, _min_tier_for_level())
	_render()
	visible = true
	get_tree().paused = true


func _min_tier_for_level() -> String:
	# Level-up picks gradually drop the lowest tiers from the pool so late-game
	# rolls trend toward bigger choices. Pure shop / shrine rolls keep the
	# default of "common".
	var lvl: int = int(GameState.run_level if "run_level" in GameState else 1)
	if lvl >= 12:
		return "rare"
	if lvl >= 6:
		return "uncommon"
	return "common"


func open_with(upgrades: Array) -> void:
	_offered = upgrades.duplicate()
	_render()
	visible = true
	get_tree().paused = true


func _render() -> void:
	_title.text = "Choose an Upgrade"
	_hint.text = "Click a card to install on the Chrono-Pistol."
	for c in _row.get_children():
		c.queue_free()
	for upgrade in _offered:
		_row.add_child(_build_card(upgrade))


func _build_card(upgrade: Dictionary) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.toggle_mode = false
	card.flat = false
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_on_card_pressed.bind(upgrade))

	# Rarity-themed background + glowing border.
	var tier_key: String = String(upgrade.get("tier", "common"))
	var tier_color: Color = TIER_COLORS.get(tier_key, Color.WHITE)
	var bg_color: Color = TIER_BG.get(tier_key, Color(0.16, 0.16, 0.20, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = tier_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.5)
	style.shadow_size = 10
	# Apply the same styled box to all of Button's draw states so the rarity
	# glow stays consistent on hover / press / focus.
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color.lightened(0.08)
	hover.shadow_size = 16
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_color.darkened(0.10)
	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_stylebox_override("focus", hover)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var tier := Label.new()
	tier.text = tier_key.to_upper()
	tier.add_theme_color_override("font_color", tier_color)
	tier.add_theme_font_size_override("font_size", 16)
	vbox.add_child(tier)

	var name_label := Label.new()
	name_label.text = upgrade.get("name", upgrade.get("id", "???"))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", tier_color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var desc := Label.new()
	desc.text = upgrade.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	var tags := Label.new()
	tags.text = "tags: " + ", ".join(upgrade.get("tags", []))
	tags.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	tags.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tags)

	return card


func _on_card_pressed(upgrade: Dictionary) -> void:
	var upgrade_id := String(upgrade.get("id", ""))
	if upgrade_id != "":
		GameState.add_run_upgrade(upgrade_id)
	_close(upgrade_id)


func _on_reroll_pressed() -> void:
	# Free reroll for the prototype. Will become a paid/limited token in v1.
	_offered = UpgradePool.roll(3, _era, _min_tier_for_level())
	_render()


func _close(picked_id: String) -> void:
	visible = false
	get_tree().paused = false
	closed.emit(picked_id)
	queue_free()
