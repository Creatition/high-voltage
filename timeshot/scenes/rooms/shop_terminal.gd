extends Area2D
class_name ShopTerminal
## A purchaseable upgrade kiosk. Rolls one upgrade on _ready, displays its
## name + price; on interact the player spends currency and the upgrade is
## applied to the gun. Insufficient funds shake the price label red.

@export var price: int = 25
@export var era: String = "any"

@onready var _name_label: Label = $NameLabel
@onready var _price_label: Label = $PriceLabel
@onready var _interact_label: Label = $InteractLabel

var _upgrade: Dictionary = {}
var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_roll_offer()
	GameState.currency_changed.connect(_refresh_affordability.unbind(1))
	_refresh_affordability()


func _process(_delta: float) -> void:
	_interact_label.visible = _player_in_range and not _consumed
	if _player_in_range and not _consumed and Input.is_action_just_pressed("interact"):
		_attempt_buy()


func _roll_offer() -> void:
	# Avoid offering upgrades the player already owns.
	var rolled := UpgradePool.roll(1, era)
	if rolled.is_empty():
		_upgrade = {}
		_name_label.text = "SOLD OUT"
		_price_label.text = "-"
		return
	# Re-roll up to a few times to avoid duplicates.
	for attempt in 4:
		if not (rolled[0].get("id", "") in GameState.run_upgrades):
			break
		rolled = UpgradePool.roll(1, era)
	_upgrade = rolled[0]
	_name_label.text = _upgrade.get("name", "?")
	_price_label.text = "$ %d" % price


func _refresh_affordability() -> void:
	if _consumed or _upgrade.is_empty():
		return
	if GameState.run_currency >= price:
		_price_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		_price_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))


func _attempt_buy() -> void:
	if _consumed or _upgrade.is_empty():
		return
	if not GameState.spend_currency(price):
		_shake_price()
		return
	_consumed = true
	GameState.add_run_upgrade(_upgrade.get("id", ""))
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("upgrade", -6.0)
	# Mark visually as bought.
	_name_label.text = "PURCHASED"
	_price_label.text = "-"
	modulate = Color(0.5, 0.5, 0.5, 0.7)


func _shake_price() -> void:
	var t := create_tween()
	t.tween_property(_price_label, "position:x", _price_label.position.x + 6.0, 0.06)
	t.tween_property(_price_label, "position:x", _price_label.position.x - 6.0, 0.06)
	t.tween_property(_price_label, "position:x", _price_label.position.x, 0.06)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = false
