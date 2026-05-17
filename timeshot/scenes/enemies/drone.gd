extends EnemyBase
class_name Drone
## Cyberpunk floating drone. Strafes around the player and fires single
## fast tracer rounds. Light HP — fragile but slippery.

@export var strafe_speed: float = 140.0
@export var acceleration: float = 520.0
@export var preferred_distance: float = 280.0
@export var distance_tolerance: float = 40.0
@export var aggro_radius: float = 900.0

@export var shoot_cooldown: float = 0.9
@export var first_shot_delay: float = 0.35
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var projectile_speed: float = 460.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _shoot_timer: float = 0.0
var _strafe_dir: int = 1


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_shoot_timer = first_shot_delay
	_strafe_dir = 1 if randf() < 0.5 else -1


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
	var radial := to_target.normalized()
	var tangent := Vector2(-radial.y, radial.x) * float(_strafe_dir)

	var desired := tangent * strafe_speed
	if dist > preferred_distance + distance_tolerance:
		desired += radial * (strafe_speed * 0.6)
	elif dist < preferred_distance - distance_tolerance:
		desired -= radial * (strafe_speed * 0.6)

	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()

	# Random strafe flip on collision feels evasive.
	if get_slide_collision_count() > 0 and randf() < 0.4:
		_strafe_dir = -_strafe_dir

	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and dist <= aggro_radius:
		_fire(radial)
		_shoot_timer = shoot_cooldown


func _fire(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
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
