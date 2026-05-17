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
const TIER_COLORS := {
	"common":    Color(0.85, 0.85, 0.9, 1.0),
	"rare":      Color(0.55, 0.80, 1.0, 1.0),
	"legendary": Color(1.0, 0.75, 0.30, 1.0),
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
	_offered = UpgradePool.roll(3, era)
	_render()
	visible = true
	get_tree().paused = true


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
	tier.text = String(upgrade.get("tier", "common")).to_upper()
	tier.add_theme_color_override("font_color", TIER_COLORS.get(upgrade.get("tier", "common"), Color.WHITE))
	tier.add_theme_font_size_override("font_size", 14)
	vbox.add_child(tier)

	var name_label := Label.new()
	name_label.text = upgrade.get("name", upgrade.get("id", "???"))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var desc := Label.new()
	desc.text = upgrade.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	var tags := Label.new()
	tags.text = "tags: " + ", ".join(upgrade.get("tags", []))
	tags.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
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
	_offered = UpgradePool.roll(3, _era)
	_render()


func _close(picked_id: String) -> void:
	visible = false
	get_tree().paused = false
	closed.emit(picked_id)
	queue_free()
