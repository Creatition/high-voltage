extends EnemyBase
class_name Archer
## Medieval ranged enemy. Kites slowly and fires 3-arrow telegraphed volleys.
## Pulls a quick draw animation (sprite turns yellow) before the volley.

@export var move_speed: float = 70.0
@export var acceleration: float = 280.0
@export var preferred_distance: float = 320.0
@export var distance_tolerance: float = 60.0
@export var aggro_radius: float = 900.0

@export var volley_cooldown: float = 2.0
@export var first_shot_delay: float = 0.6
@export var draw_time: float = 0.5
@export var arrow_count: int = 3
@export var arrow_spread_degrees: float = 14.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var projectile_speed: float = 380.0

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _shoot_timer: float = 0.0
var _drawing: bool = false
var _draw_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_shoot_timer = first_shot_delay


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()

	# Kite to preferred distance, but stop while drawing.
	if _drawing:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	elif dist > preferred_distance + distance_tolerance:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
	elif dist < preferred_distance - distance_tolerance:
		velocity = velocity.move_toward(-to_target.normalized() * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	move_and_slide()

	if _drawing:
		_draw_timer -= delta
		if _draw_timer <= 0.0:
			_release_volley()
	else:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0 and dist <= aggro_radius:
			_start_draw()


func _start_draw() -> void:
	_drawing = true
	_draw_timer = draw_time
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.6, 1.4, 0.4, 1), draw_time * 0.8)
		t.tween_property(sprite, "modulate", Color.WHITE, draw_time * 0.2)


func _release_volley() -> void:
	_drawing = false
	_shoot_timer = volley_cooldown
	if _target == null:
		return
	var base_dir := (_target.global_position - global_position).normalized()
	var spread := deg_to_rad(arrow_spread_degrees)
	for i in arrow_count:
		var offset := 0.0
		if arrow_count > 1:
			offset = spread * (float(i) - float(arrow_count - 1) * 0.5)
		_spawn_arrow(base_dir.rotated(offset))


func _spawn_arrow(dir: Vector2) -> void:
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
