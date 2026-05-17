extends EnemyBase
class_name AlienSentry
## Slow, tough, long-range. Fires bigger, slower projectiles than the Shooter
## and barely moves — its job is to lock down sightlines.

@export var move_speed: float = 50.0
@export var acceleration: float = 250.0
@export var preferred_distance: float = 360.0
@export var distance_tolerance: float = 80.0
@export var aggro_radius: float = 900.0

@export var shoot_cooldown: float = 1.6
@export var first_shot_delay: float = 0.5
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var burst_size: int = 1
@export var burst_spread_degrees: float = 8.0
@export var projectile_scale: Vector2 = Vector2(1.6, 1.6)
@export var projectile_speed: float = 280.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _shoot_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_shoot_timer = first_shot_delay


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	_shoot_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()

	# Sentries inch forward/back to maintain range, but they're sluggish.
	if dist > aggro_radius:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	elif dist > preferred_distance + distance_tolerance:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
	elif dist < preferred_distance - distance_tolerance:
		velocity = velocity.move_toward(-to_target.normalized() * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	move_and_slide()

	if _shoot_timer <= 0.0 and dist <= aggro_radius:
		_fire_burst()
		_shoot_timer = shoot_cooldown


func _fire_burst() -> void:
	if projectile_scene == null or _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var spread := deg_to_rad(burst_spread_degrees)
	for i in burst_size:
		var offset := 0.0
		if burst_size > 1:
			offset = spread * (float(i) - float(burst_size - 1) * 0.5)
		_spawn_projectile(base_dir.rotated(offset))


func _spawn_projectile(dir: Vector2) -> void:
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.scale = projectile_scale
	if "speed" in proj:
		proj.speed = projectile_speed
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
