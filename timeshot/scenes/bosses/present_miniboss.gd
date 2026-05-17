extends EnemyBase
class_name PresentMiniboss
## First era's mini-boss: "Riot Sergeant".
## Two-phase attack:
##   Phase 1 (HP > 50%): Charge at the player + occasional 3-bullet burst.
##   Phase 2 (HP <= 50%): Bullet ring spam + sidesteps.

@export var move_speed: float = 110.0
@export var acceleration: float = 600.0
@export var preferred_distance: float = 240.0
@export var charge_speed: float = 360.0
@export var charge_windup: float = 0.6
@export var charge_duration: float = 0.7
@export var charge_cooldown: float = 3.2
@export var burst_cooldown: float = 2.4
@export var ring_cooldown: float = 2.0
@export var ring_bullet_count: int = 12

@export var projectile_scene: PackedScene

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _charge_timer: float = 0.0
var _charge_state: int = 0   # 0 = idle, 1 = winding up, 2 = charging
var _charge_dir: Vector2 = Vector2.RIGHT
var _burst_timer: float = 0.0
var _ring_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	_burst_timer = burst_cooldown
	_ring_timer = ring_cooldown


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.5
	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var phase_two := _is_phase_two()

	match _charge_state:
		0:
			_kite(delta)
		1:
			_charge_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _charge_timer <= 0.0:
				_charge_dir = (_target.global_position - global_position).normalized()
				_charge_state = 2
				_charge_timer = charge_duration
		2:
			_charge_timer -= delta
			velocity = _charge_dir * charge_speed
			if _charge_timer <= 0.0:
				_charge_state = 0
				_charge_timer = charge_cooldown

	if _charge_state == 0:
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_start_charge()

	move_and_slide()

	_burst_timer -= delta
	_ring_timer -= delta

	if _burst_timer <= 0.0 and not phase_two and _charge_state == 0:
		_fire_burst(3)
		_burst_timer = burst_cooldown
	if _ring_timer <= 0.0 and phase_two:
		_fire_ring(ring_bullet_count)
		_ring_timer = ring_cooldown


func _is_phase_two() -> bool:
	if health == null:
		return false
	return float(health.current_hp) / float(max(1, health.max_hp)) <= 0.5


func _kite(delta: float) -> void:
	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	var dir := to_target.normalized()
	if dist > preferred_distance + 40.0:
		velocity = velocity.move_toward(dir * move_speed, acceleration * delta)
	elif dist < preferred_distance - 40.0:
		velocity = velocity.move_toward(-dir * move_speed, acceleration * delta)
	else:
		var side := Vector2(-dir.y, dir.x)
		velocity = velocity.move_toward(side * move_speed * 0.7, acceleration * delta)


func _start_charge() -> void:
	_charge_state = 1
	_charge_timer = charge_windup
	# Telegraph: flash red briefly.
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.6, 0.6, 0.6, 1), 0.1)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _fire_burst(count: int) -> void:
	if projectile_scene == null or _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var spread := deg_to_rad(14.0)
	for i in count:
		var angle_offset := spread * (float(i) - float(count - 1) * 0.5)
		_spawn_projectile(base_dir.rotated(angle_offset))


func _fire_ring(count: int) -> void:
	if projectile_scene == null:
		return
	var step := TAU / float(count)
	for i in count:
		var dir := Vector2.RIGHT.rotated(step * float(i))
		_spawn_projectile(dir)


func _spawn_projectile(dir: Vector2) -> void:
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		proj.launch(dir)


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
