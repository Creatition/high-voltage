extends CanvasLayer
class_name HUD
## In-run heads-up display. Shows hearts (HP), currency, and active upgrade pips.
## Auto-binds to the first node in the "players" group when added to the tree.
## Also shows a top-center BOSS HP bar when a node in the "bosses" group is alive.

const HEART_FULL := Color(0.95, 0.30, 0.35, 1.0)
const HEART_EMPTY := Color(0.20, 0.20, 0.24, 1.0)

@onready var _hearts_box: HBoxContainer = $Margin/Top/HeartsBox
@onready var _currency_label: Label = $Margin/Top/CurrencyBox/CurrencyLabel
@onready var _upgrades_box: HBoxContainer = $Margin/Bottom/UpgradesBox
@onready var _boss_layer: CenterContainer = $BossBarLayer
@onready var _boss_name: Label = $BossBarLayer/BossBox/BossName
@onready var _boss_hp: ProgressBar = $BossBarLayer/BossBox/BossHP

var _player: Node = null
var _health: HealthComponent = null
var _boss: Node = null
var _boss_health: HealthComponent = null


func _ready() -> void:
	GameState.currency_changed.connect(_on_currency_changed)
	GameState.upgrade_added.connect(_on_upgrade_added)
	_currency_label.text = "$ %d" % GameState.run_currency
	_rebuild_upgrades()
	# Defer player lookup so the scene has had a chance to fully spawn.
	call_deferred("_bind_player")
	# Watch for any boss entering or leaving the scene.
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	# In case a boss is already alive when the HUD spawns.
	call_deferred("_scan_for_boss")


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


# ---------------------------------------------------------------------------
# Boss HP bar
# ---------------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	# Defer the group check: enemies call add_to_group("bosses") in _ready,
	# which hasn't run yet at node_added time. We also wait so HealthComponent
	# has had its _ready (where current_hp is initialized).
	call_deferred("_try_bind_boss", node)


func _try_bind_boss(node: Node) -> void:
	if _boss != null and is_instance_valid(_boss):
		return
	if not is_instance_valid(node):
		return
	if node.is_in_group("bosses"):
		_bind_boss(node)


func _on_node_removed(node: Node) -> void:
	if node == _boss:
		_unbind_boss()


func _scan_for_boss() -> void:
	if _boss != null:
		return
	var bosses := get_tree().get_nodes_in_group("bosses")
	if not bosses.is_empty():
		_bind_boss(bosses[0])


func _bind_boss(boss: Node) -> void:
	_boss = boss
	_boss_health = boss.get_node_or_null("HealthComponent") as HealthComponent
	if _boss_health == null:
		_unbind_boss()
		return
	_boss_health.damaged.connect(_on_boss_damaged)
	_boss_health.died.connect(_on_boss_died)
	_boss_name.text = _format_boss_name(boss.name)
	_boss_hp.max_value = float(_boss_health.max_hp)
	_boss_hp.value = float(_boss_health.current_hp)
	_boss_layer.visible = true


func _format_boss_name(raw: String) -> String:
	# "alien_mothership" -> "ALIEN MOTHERSHIP"; "@TRex@3" -> "TREX".
	var cleaned := raw.lstrip("@")
	var at := cleaned.find("@")
	if at >= 0:
		cleaned = cleaned.substr(0, at)
	cleaned = cleaned.replace("_", " ")
	return cleaned.to_upper()


func _on_boss_damaged(_amount: int, current: int, max_value: int) -> void:
	_boss_hp.max_value = float(max_value)
	_boss_hp.value = float(current)


func _on_boss_died() -> void:
	_unbind_boss()


func _unbind_boss() -> void:
	if _boss_health != null and is_instance_valid(_boss_health):
		if _boss_health.damaged.is_connected(_on_boss_damaged):
			_boss_health.damaged.disconnect(_on_boss_damaged)
		if _boss_health.died.is_connected(_on_boss_died):
			_boss_health.died.disconnect(_on_boss_died)
	_boss = null
	_boss_health = null
	if _boss_layer != null:
		_boss_layer.visible = false
