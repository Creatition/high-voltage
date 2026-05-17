extends EnemyBase
class_name Raptor
## Prehistoric swarmer. Fast, low HP, pack hunter. Charges in short bursts
## with a wind-up pause. Designed to be dangerous in numbers.

@export var prowl_speed: float = 130.0
@export var charge_speed: float = 380.0
@export var acceleration: float = 1100.0
@export var charge_trigger_distance: float = 280.0
@export var windup_duration: float = 0.3
@export var charge_duration: float = 0.4
@export var recover_duration: float = 0.7

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _state: int = 0   # 0 prowl, 1 windup, 2 charge, 3 recover
var _state_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.4

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	_state_timer -= delta

	match _state:
		0:
			velocity = velocity.move_toward(to_target.normalized() * prowl_speed, acceleration * delta)
			if dist <= charge_trigger_distance:
				_state = 1
				_state_timer = windup_duration
				_charge_dir = to_target.normalized() if dist > 0.1 else Vector2.RIGHT
				if sprite != null:
					var t := create_tween()
					t.tween_property(sprite, "modulate", Color(1.8, 1.4, 0.4, 1), windup_duration * 0.8)
					t.tween_property(sprite, "modulate", Color.WHITE, windup_duration * 0.2)
		1:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _state_timer <= 0.0:
				_state = 2
				_state_timer = charge_duration
		2:
			velocity = _charge_dir * charge_speed
			if _state_timer <= 0.0:
				_state = 3
				_state_timer = recover_duration
		3:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _state_timer <= 0.0:
				_state = 0

	move_and_slide()


func _retarget() -> void:
	var closest: Node2D = null
	var best_dist := INF
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			var d := global_position.distance_squared_to(p.global_position)
			if d < best_dist:
				best_dist = d
				closest = p
	_target = closest
