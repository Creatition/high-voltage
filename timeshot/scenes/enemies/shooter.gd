extends EnemyBase
class_name ShooterEnemy
## Maintains a preferred distance from the player and fires enemy projectiles.

@export var move_speed: float = 75.0
@export var acceleration: float = 500.0
@export var preferred_distance: float = 280.0
@export var distance_tolerance: float = 40.0
@export var aggro_radius: float = 800.0

@export var shoot_cooldown: float = 1.4
@export var projectile_scene: PackedScene
@export var first_shot_delay: float = 0.6

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
		_retarget_timer = 0.5

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()
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
		_shoot_at(_target.global_position)
		_shoot_timer = shoot_cooldown


func _shoot_at(world_pos: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		var dir := (world_pos - global_position)
		if dir.length() < 0.001:
			dir = Vector2.RIGHT
		proj.launch(dir.normalized())


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
