extends CanvasLayer
class_name HUD
## In-run heads-up display. Shows hearts (HP), currency, and active upgrade pips.
## Auto-binds to the first node in the "players" group when added to the tree.

const HEART_FULL := Color(0.95, 0.30, 0.35, 1.0)
const HEART_EMPTY := Color(0.20, 0.20, 0.24, 1.0)

@onready var _hearts_box: HBoxContainer = $Margin/Top/HeartsBox
@onready var _currency_label: Label = $Margin/Top/CurrencyBox/CurrencyLabel
@onready var _upgrades_box: HBoxContainer = $Margin/Bottom/UpgradesBox

var _player: Node = null
var _health: HealthComponent = null


func _ready() -> void:
	GameState.currency_changed.connect(_on_currency_changed)
	GameState.upgrade_added.connect(_on_upgrade_added)
	_currency_label.text = "$ %d" % GameState.run_currency
	_rebuild_upgrades()
	# Defer player lookup so the scene has had a chance to fully spawn.
	call_deferred("_bind_player")


func _bind_player() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		# Try again next frame if no player yet (room loading order).
		await get_tree().process_frame
		players = get_tree().get_nodes_in_group("players")
		if players.is_empty():
			return
	_player = players[0]
	_health = _player.get_node_or_null("HealthComponent") as HealthComponent
	if _health != null:
		_health.damaged.connect(_refresh_hearts.unbind(3))
		_health.healed.connect(_refresh_hearts.unbind(3))
		_refresh_hearts()


func _refresh_hearts() -> void:
	for c in _hearts_box.get_children():
		c.queue_free()
	if _health == null:
		return
	for i in _health.max_hp:
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(20, 20)
		heart.color = HEART_FULL if i < _health.current_hp else HEART_EMPTY
		_hearts_box.add_child(heart)


func _on_currency_changed(amount: int) -> void:
	_currency_label.text = "$ %d" % amount


func _on_upgrade_added(_upgrade_id: String) -> void:
	_rebuild_upgrades()


func _rebuild_upgrades() -> void:
	for c in _upgrades_box.get_children():
		c.queue_free()
	for upgrade_id in GameState.run_upgrades:
		var data := UpgradePool.get_by_id(upgrade_id)
		var pip := Label.new()
		pip.text = data.get("name", upgrade_id) if not data.is_empty() else upgrade_id
		pip.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		pip.add_theme_font_size_override("font_size", 14)
		_upgrades_box.add_child(pip)
