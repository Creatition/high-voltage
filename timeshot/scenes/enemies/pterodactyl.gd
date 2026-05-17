extends EnemyBase
class_name Pterodactyl
## Dive-bomber: circles at altitude, periodically swoops at the player's
## projected position with a telegraphed shadow line, then climbs back.
##
## Implemented as a 2D enemy that ignores walls during a dive — we model
## "altitude" with collision layer 0 and shape scaling.

@export var orbit_speed: float = 130.0
@export var orbit_radius: float = 240.0
@export var orbit_center: Vector2 = Vector2(640, 360)
@export var dive_charge: float = 0.6
@export var dive_speed: float = 520.0
@export var dive_duration: float = 0.7
@export var climb_duration: float = 0.55
@export var dive_cooldown: float = 1.4

@onready var sprite_node: Sprite2D = sprite
@onready var body_collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var contact: Area2D = get_node_or_null("ContactHitbox") as Area2D

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _state: int = 0   # 0 orbit, 1 charge, 2 dive, 3 climb
var _state_timer: float = 0.0
var _orbit_angle: float = 0.0
var _dive_target_pos: Vector2 = Vector2.ZERO
var _dive_dir: Vector2 = Vector2.RIGHT
var _cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_orbit_angle = randf() * TAU
	_cooldown = dive_cooldown


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.5

	_state_timer -= delta
	_cooldown -= delta

	match _state:
		0:
			_orbit(delta)
			if _cooldown <= 0.0 and _target != null:
				_begin_dive()
		1:
			# Hover-charge: stop, flash, point at intercept.
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				_state = 2
				_state_timer = dive_duration
				_set_airborne(false)
		2:
			velocity = _dive_dir * dive_speed
			if _state_timer <= 0.0:
				_state = 3
				_state_timer = climb_duration
				_set_airborne(true)
		3:
			# Climb back toward orbit center.
			var to_center := orbit_center - global_position
			velocity = to_center.normalized() * (orbit_speed * 1.4)
			if _state_timer <= 0.0:
				_state = 0
				_cooldown = dive_cooldown

	move_and_slide()


func _orbit(delta: float) -> void:
	_orbit_angle += (orbit_speed / orbit_radius) * delta
	var desired := orbit_center + Vector2.RIGHT.rotated(_orbit_angle) * orbit_radius
	velocity = (desired - global_position) * 4.0


func _begin_dive() -> void:
	if _target == null:
		return
	_state = 1
	_state_timer = dive_charge
	_dive_target_pos = _target.global_position
	_dive_dir = (_dive_target_pos - global_position).normalized()
	if sprite_node != null:
		var t := create_tween()
		t.tween_property(sprite_node, "modulate", Color(1.6, 1.4, 0.4, 1), dive_charge * 0.8)
		t.tween_property(sprite_node, "modulate", Color.WHITE, dive_charge * 0.2)
		# Visually scale up as it descends.
		t.parallel().tween_property(sprite_node, "scale", Vector2(1.6, 1.6), dive_charge)


func _set_airborne(airborne: bool) -> void:
	# Disable body+contact collisions while airborne to fake altitude.
	if body_collision != null:
		body_collision.disabled = airborne
	if contact != null:
		contact.monitoring = not airborne
		contact.monitorable = not airborne
	if sprite_node != null:
		var scale_to := Vector2.ONE if airborne else Vector2(1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(sprite_node, "scale", scale_to, 0.2)


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
