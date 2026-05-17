extends EnemyBase
class_name AlienMothership
## Final-era mini-boss. Rotates through three patterns based on a phase clock:
##   0: Beam Sweep — quick burst of telegraphed darts in a sweeping arc.
##   1: Spawn Sentries — calls in 2 Alien Grunts to harass.
##   2: Pulse Ring — explosive ring of slow projectiles.
##
## Patterns advance on a timer, NOT on HP — the mothership is meant to be a
## test of pattern reading.

@export var move_speed: float = 70.0
@export var acceleration: float = 320.0
@export var hover_radius: float = 360.0   # distance from center it likes to keep
@export var center: Vector2 = Vector2(640, 360)

@export var phase_duration: float = 3.6
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var grunt_scene: PackedScene = preload("res://scenes/enemies/alien_grunt.tscn")

@export var sweep_dart_count: int = 9
@export var sweep_arc_degrees: float = 90.0
@export var ring_count: int = 14
@export var grunt_spawn_count: int = 2

var _target: Node2D = null
var _phase: int = 0
var _phase_timer: float = 0.0
var _retarget_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	_phase_timer = phase_duration
	# Telegraph the next pattern visually with a recurring pulse.


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	_hover(delta)
	move_and_slide()

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_run_phase(_phase)
		_phase = (_phase + 1) % 3
		_phase_timer = phase_duration


func _hover(delta: float) -> void:
	# Drift slowly around the room center, biasing away from the player when close.
	var to_center := center - global_position
	var desired: Vector2
	if _target != null and global_position.distance_to(_target.global_position) < 220.0:
		var away := (global_position - _target.global_position).normalized()
		desired = away * move_speed
	else:
		desired = to_center.normalized() * move_speed
	velocity = velocity.move_toward(desired, acceleration * delta)


func _run_phase(phase: int) -> void:
	match phase:
		0:
			_beam_sweep()
		1:
			_spawn_sentries()
		2:
			_pulse_ring()


func _beam_sweep() -> void:
	if _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var arc := deg_to_rad(sweep_arc_degrees)
	var step := 0.0
	if sweep_dart_count > 1:
		step = arc / float(sweep_dart_count - 1)
	var start_angle := -arc * 0.5
	for i in sweep_dart_count:
		var dir := base_dir.rotated(start_angle + step * float(i))
		_spawn_proj(dir)


func _pulse_ring() -> void:
	var step := TAU / float(ring_count)
	for i in ring_count:
		_spawn_proj(Vector2.RIGHT.rotated(step * float(i)))


func _spawn_sentries() -> void:
	if grunt_scene == null:
		return
	for i in grunt_spawn_count:
		var angle := randf() * TAU
		var offset := Vector2.RIGHT.rotated(angle) * 80.0
		var grunt := grunt_scene.instantiate()
		get_tree().current_scene.add_child(grunt)
		grunt.global_position = global_position + offset


func _spawn_proj(dir: Vector2) -> void:
	if projectile_scene == null:
		return
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
