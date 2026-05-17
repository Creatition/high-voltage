extends EnemyBase
class_name AlienGrunt
## Faster than a Chaser, slightly less HP. Lunges in straight bursts.
## When the player gets close it lunges; otherwise it cruises in.

@export var cruise_speed: float = 150.0
@export var lunge_speed: float = 340.0
@export var lunge_distance: float = 220.0
@export var lunge_duration: float = 0.35
@export var lunge_cooldown: float = 1.4
@export var acceleration: float = 1000.0
@export var aggro_radius: float = 800.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _lunge_state: int = 0    # 0 = cruise, 1 = lunging, 2 = recovering
var _lunge_timer: float = 0.0
var _lunge_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.5

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()

	match _lunge_state:
		0:
			if dist <= lunge_distance:
				_start_lunge(to_target.normalized())
			else:
				velocity = velocity.move_toward(to_target.normalized() * cruise_speed, acceleration * delta)
		1:
			_lunge_timer -= delta
			velocity = _lunge_dir * lunge_speed
			if _lunge_timer <= 0.0:
				_lunge_state = 2
				_lunge_timer = lunge_cooldown
		2:
			_lunge_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _lunge_timer <= 0.0:
				_lunge_state = 0

	move_and_slide()


func _start_lunge(dir: Vector2) -> void:
	_lunge_state = 1
	_lunge_timer = lunge_duration
	_lunge_dir = dir
	# Tiny windup flash so the player can read the lunge.
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.4, 1.4, 0.8, 1), 0.07)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.12)


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
