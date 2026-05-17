extends EnemyBase
class_name SniperEnemy
## Stationary long-range enemy. Telegraphs a single heavy shot, then fires a
## fast bullet straight along the telegraph line. Strong if you stand still,
## avoidable if you keep moving.

@export var aggro_radius: float = 900.0
@export var aim_duration: float = 0.9
@export var cooldown: float = 1.8
@export var bullet_speed: float = 360.0
@export var bullet_damage: int = 2
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _state_timer: float = 0.0
var _state: int = 0   # 0 = idle/cooldown, 1 = aiming
var _aim_at: Vector2 = Vector2.ZERO
var _telegraph: Line2D


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_state_timer = cooldown
	_telegraph = Line2D.new()
	_telegraph.width = 2.0
	_telegraph.default_color = Color(1.0, 0.3, 0.3, 0.0)
	add_child(_telegraph)


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	if _target == null:
		_clear_telegraph()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	_state_timer -= delta
	match _state:
		0:
			# Idle / cooldown.
			_clear_telegraph()
			if _state_timer <= 0.0 and dist <= aggro_radius:
				_state = 1
				_state_timer = aim_duration
				_aim_at = _target.global_position
		1:
			# Track-aim and show a red telegraph beam.
			_aim_at = _aim_at.lerp(_target.global_position, 0.15)
			_draw_telegraph()
			if _state_timer <= 0.0:
				_fire()
				_state = 0
				_state_timer = cooldown


func _draw_telegraph() -> void:
	_telegraph.clear_points()
	_telegraph.add_point(Vector2.ZERO)
	_telegraph.add_point(_aim_at - global_position)
	var alpha := clampf(1.0 - (_state_timer / maxf(0.01, aim_duration)), 0.0, 1.0)
	_telegraph.default_color = Color(1.0, 0.25, 0.25, alpha)


func _clear_telegraph() -> void:
	_telegraph.clear_points()
	_telegraph.default_color = Color(1.0, 0.3, 0.3, 0.0)


func _fire() -> void:
	_clear_telegraph()
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if "speed" in proj:
		proj.speed = bullet_speed
	if "lifetime" in proj:
		proj.lifetime = 3.0
	# Beef up its damage to make the slow telegraph cycle worth respecting.
	for c in proj.get_children():
		if c is HitboxComponent:
			c.damage = bullet_damage
			break
	if proj.has_method("launch"):
		var dir := (_aim_at - global_position)
		if dir.length() < 0.001:
			dir = Vector2.RIGHT
		proj.launch(dir.normalized())
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("shoot", -10.0)


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
