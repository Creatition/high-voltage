extends EnemyBase
class_name BlackKnight
## Medieval boss. Two interleaved patterns:
##   PHASE A (>50% HP): "duel" — slow approach, big telegraphed swings with
##     an arc of darts in front of him.
##   PHASE B (<50% HP): adds "ground slam" — pauses to slam, emitting an
##     expanding ring of slow dust projectiles in a full circle.
##
## Picks pattern by a phase timer; HP threshold flips a flag that enables
## the ground slam in the rotation.

@export var move_speed: float = 100.0
@export var acceleration: float = 360.0
@export var preferred_distance: float = 100.0

@export var phase_duration: float = 2.4
@export var slam_charge_time: float = 0.7
@export var swing_arc_degrees: float = 70.0
@export var swing_dart_count: int = 5
@export var slam_ring_count: int = 18
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var projectile_speed: float = 240.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _phase: int = 0
var _phase_timer: float = 0.0
var _enraged: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	_phase_timer = phase_duration
	if health != null:
		health.damaged.connect(_check_enrage)


func _check_enrage(_amount: int, current: int, max_value: int) -> void:
	if not _enraged and float(current) / float(maxi(1, max_value)) <= 0.5:
		_enraged = true
		# Flash hard so player sees rage trigger.
		if sprite != null:
			var t := create_tween()
			t.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1), 0.15)
			t.tween_property(sprite, "modulate", Color.WHITE, 0.35)


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	_chase(delta)
	move_and_slide()

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_run_phase()
		# Cycle through patterns; if enraged include slam.
		var max_phase := 2 if _enraged else 1
		_phase = (_phase + 1) % (max_phase + 1)
		_phase_timer = phase_duration


func _chase(delta: float) -> void:
	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		return
	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	if dist > preferred_distance:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)


func _run_phase() -> void:
	match _phase:
		0:
			_swing_arc()
		1:
			_swing_arc()
		2:
			_ground_slam()


func _swing_arc() -> void:
	if _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var arc := deg_to_rad(swing_arc_degrees)
	var step := 0.0
	if swing_dart_count > 1:
		step = arc / float(swing_dart_count - 1)
	for i in swing_dart_count:
		var off := -arc * 0.5 + step * float(i)
		_spawn_proj(base_dir.rotated(off))


func _ground_slam() -> void:
	# Brief charge then full ring of slow projectiles.
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.8, 1.4, 0.5, 1), slam_charge_time * 0.6)
		t.tween_property(sprite, "modulate", Color.WHITE, slam_charge_time * 0.4)
	await get_tree().create_timer(slam_charge_time).timeout
	if not is_instance_valid(self):
		return
	var step := TAU / float(slam_ring_count)
	for i in slam_ring_count:
		_spawn_proj(Vector2.RIGHT.rotated(step * float(i)), projectile_speed * 0.7)


func _spawn_proj(dir: Vector2, speed_override: float = projectile_speed) -> void:
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if "speed" in proj:
		proj.speed = speed_override
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
