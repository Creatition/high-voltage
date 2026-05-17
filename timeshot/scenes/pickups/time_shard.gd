extends Area2D
class_name TimeShard
## A collectible currency pickup. On player overlap, grants `value` currency
## and despawns with a tiny pop.
##
## Bosses drop a handful as a visible reward (separate from the direct
## currency_on_death the enemy adds — those still work for regular mobs).

@export var value: int = 5
@export var auto_collect_radius: float = 28.0
@export var magnet_radius: float = 140.0
@export var magnet_speed: float = 360.0

@onready var sprite: Sprite2D = $Sprite2D

var _collected: bool = false
var _life: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Gentle hover bob.
	var t := create_tween().set_loops()
	t.tween_property(sprite, "position:y", -3.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "position:y", 3.0, 0.5).set_trans(Tween.TRANS_SINE)


func _physics_process(delta: float) -> void:
	_life += delta
	if _collected:
		return
	# Magnet toward the nearest player when close.
	var p := _nearest_player()
	if p == null:
		return
	var to_p := p.global_position - global_position
	var dist := to_p.length()
	if dist <= auto_collect_radius:
		_collect(p)
	elif dist <= magnet_radius:
		global_position = global_position.move_toward(p.global_position, magnet_speed * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		_collect(body)


func _on_area_entered(area: Area2D) -> void:
	# Some player setups use the hurtbox area. Either is fine for pickups.
	var p := area.get_parent()
	if p != null and p.is_in_group("players"):
		_collect(p)


func _collect(_by: Node) -> void:
	if _collected:
		return
	_collected = true
	GameState.add_currency(value)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("pickup", -10.0)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ZERO, 0.12)
	t.tween_callback(queue_free)


func _nearest_player() -> Node2D:
	var closest: Node2D = null
	var best := INF
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			var d := global_position.distance_squared_to(p.global_position)
			if d < best:
				best = d
				closest = p
	return closest
