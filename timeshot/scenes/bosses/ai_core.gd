extends EnemyBase
class_name AICore
## Cyberpunk boss. Stationary central core that pivots and fires patterns:
##   0: Rotor — a slow continuous rotating fan of 4 projectiles for 2s.
##   1: Aimed burst — 5 shots aimed at the player with mild spread.
##   2: Spawn drones — calls 2 drones.
##   3 (enraged only): Cross — 4 simultaneous lines on the cardinals.

@export var pivot_speed_deg: float = 90.0
@export var phase_duration: float = 3.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var drone_scene: PackedScene = preload("res://scenes/enemies/drone.tscn")
@export var rotor_duration: float = 2.0
@export var rotor_interval: float = 0.18
@export var rotor_speed: float = 240.0
@export var burst_count: int = 5
@export var burst_spread_degrees: float = 22.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _phase: int = 0
var _phase_timer: float = 0.0
var _enraged: bool = false
var _rotor_angle: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	_phase_timer = phase_duration
	if health != null:
		health.damaged.connect(_check_enrage)


func _check_enrage(_amount: int, current: int, max_value: int) -> void:
	if _enraged:
		return
	if float(current) / float(maxi(1, max_value)) <= 0.45:
		_enraged = true
		phase_duration *= 0.75
		if sprite != null:
			var t := create_tween()
			t.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.8, 1), 0.2)
			t.tween_property(sprite, "modulate", Color(0.7, 0.95, 1, 1), 0.4)


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	# Stationary core — no chase.
	velocity = Vector2.ZERO
	move_and_slide()

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_run_phase()
		var max_phase := 3 if _enraged else 2
		_phase = (_phase + 1) % (max_phase + 1)
		_phase_timer = phase_duration


func _run_phase() -> void:
	match _phase:
		0:
			_rotor()
		1:
			_aimed_burst()
		2:
			_spawn_drones()
		3:
			_cross()


func _rotor() -> void:
	var elapsed := 0.0
	while elapsed < rotor_duration and is_instance_valid(self):
		for k in 4:
			var ang := _rotor_angle + (TAU / 4.0) * float(k)
			_spawn_proj(Vector2.RIGHT.rotated(ang), rotor_speed)
		_rotor_angle += deg_to_rad(pivot_speed_deg) * rotor_interval
		await get_tree().create_timer(rotor_interval).timeout
		elapsed += rotor_interval


func _aimed_burst() -> void:
	if _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var spread := deg_to_rad(burst_spread_degrees)
	var step := 0.0
	if burst_count > 1:
		step = spread / float(burst_count - 1)
	for i in burst_count:
		var off := -spread * 0.5 + step * float(i)
		_spawn_proj(base_dir.rotated(off), 360.0)


func _spawn_drones() -> void:
	if drone_scene == null:
		return
	for i in 2:
		var d := drone_scene.instantiate()
		get_tree().current_scene.add_child(d)
		var angle := randf() * TAU
		d.global_position = global_position + Vector2.RIGHT.rotated(angle) * 110.0


func _cross() -> void:
	# Fire 4 cardinals as a quick triple-burst.
	for burst in 3:
		for k in 4:
			var ang := (TAU / 4.0) * float(k) + (deg_to_rad(10.0) * float(burst - 1))
			_spawn_proj(Vector2.RIGHT.rotated(ang), 300.0)
		await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(self):
			return


func _spawn_proj(dir: Vector2, spd: float) -> void:
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if "speed" in proj:
		proj.speed = spd
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
