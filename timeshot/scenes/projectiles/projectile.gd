extends Area2D
class_name Projectile
## Generic projectile. Travels in a launched direction, despawns on lifetime,
## wall hit, or hurtbox hit. Damage is applied via a child HitboxComponent.
##
## Two flavors share this script:
##  - Player projectiles (collision_layer L6, mask L1 + L5)
##  - Enemy projectiles  (collision_layer L7, mask L1 + L4)
## The .tscn variant configures layers and Hitbox.owner_id.

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var pierce: int = 0           # how many extra enemies to pass through
@export var bounces: int = 0          # how many wall bounces remain
@export var homing_strength: float = 0.0   # 0 = no homing; degrees/sec turn rate
@export var explosion_scene: PackedScene   # optional — spawned on despawn

var _direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0
var _pierce_left: int = 0
var _hit_targets: Array = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_pierce_left = pierce


func launch(direction: Vector2) -> void:
	_direction = direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		_despawn()
		return
	if homing_strength > 0.0:
		_apply_homing(delta)
	position += _direction * speed * delta


func _apply_homing(delta: float) -> void:
	var target := _find_nearest_target()
	if target == null:
		return
	var desired := (target.global_position - global_position).normalized()
	var turn_rate := deg_to_rad(homing_strength) * delta
	_direction = _direction.rotated(clampf(_direction.angle_to(desired), -turn_rate, turn_rate))
	rotation = _direction.angle()


func _find_nearest_target() -> Node2D:
	# Find closest node in group "enemies" (or "players" if enemy projectile).
	var group_name := "enemies" if (collision_mask & 16) != 0 else "players"
	var best: Node2D = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node2D:
			var d := global_position.distance_squared_to(n.global_position)
			if d < best_dist:
				best_dist = d
				best = n
	return best


func _on_body_entered(_body: Node) -> void:
	# Hit a wall / solid body.
	if bounces > 0:
		bounces -= 1
		_bounce_off_wall()
		return
	_despawn()


func _bounce_off_wall() -> void:
	# Cheap reflect: try axis-aligned bounce based on direction sign.
	# Better wall normals can be wired in once tilemap collisions land.
	if absf(_direction.x) > absf(_direction.y):
		_direction.x *= -1.0
	else:
		_direction.y *= -1.0
	rotation = _direction.angle()


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		if area in _hit_targets:
			return
		_hit_targets.append(area)
		var hit := _get_hitbox()
		if hit != null:
			(area as HurtboxComponent).receive_hit(hit)
		if _pierce_left > 0:
			_pierce_left -= 1
		else:
			_despawn()


func _get_hitbox() -> HitboxComponent:
	for c in get_children():
		if c is HitboxComponent:
			return c
	return null


func _despawn() -> void:
	if explosion_scene != null:
		var boom := explosion_scene.instantiate()
		get_tree().current_scene.add_child(boom)
		boom.global_position = global_position
	queue_free()
