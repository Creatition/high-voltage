extends Area2D
class_name PressurePlate
## Floor plate that triggers something when the player steps on it.
##
## Two trigger modes (set by `target_kind`):
##   "fire"    — calls fire_once() on every node in `target_paths` (DartShooter list)
##   "arm"     — calls set_armed(true) on every node in `target_paths` (dormant SpikePit)
##   "disarm"  — calls set_armed(false) on every node in `target_paths`
##
## Cooldown prevents the same plate from spam-triggering each physics frame
## while the player stands on it.

@export var target_paths: Array[NodePath] = []
@export var target_kind: String = "fire"
@export var cooldown: float = 1.0
@export var one_shot: bool = false

@onready var _label: Label = $Label
@onready var _plate: ColorRect = $Plate

const COLOR_READY := Color(0.45, 0.80, 0.45, 1.0)
const COLOR_USED := Color(0.45, 0.45, 0.50, 1.0)

var _cooldown_timer: float = 0.0
var _spent: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_plate.color = COLOR_READY


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0 and not _spent:
			_plate.color = COLOR_READY


func _on_body_entered(body: Node) -> void:
	if _spent or _cooldown_timer > 0.0:
		return
	if not body.is_in_group("players"):
		return
	_trigger()


func _trigger() -> void:
	for path in target_paths:
		var node := get_node_or_null(path)
		if node == null:
			continue
		match target_kind:
			"fire":
				if node.has_method("fire_once"):
					node.fire_once()
			"arm":
				if node.has_method("set_armed"):
					node.set_armed(true)
			"disarm":
				if node.has_method("set_armed"):
					node.set_armed(false)
	if one_shot:
		_spent = true
		_plate.color = COLOR_USED
	else:
		_cooldown_timer = cooldown
		_plate.color = COLOR_USED
