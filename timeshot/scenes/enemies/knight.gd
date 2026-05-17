extends EnemyBase
class_name Knight
## Medieval melee enemy. Walks toward the player, then telegraphs a sword
## swing — during the windup it stands still and flashes white; on release
## it lunges forward a short distance with extended contact reach.
##
## Reads as: "stop ⇒ red ⇒ swing." Easy tell, punishing if ignored.

@export var walk_speed: float = 110.0
@export var acceleration: float = 700.0
@export var swing_range: float = 80.0
@export var windup_duration: float = 0.45
@export var swing_duration: float = 0.18
@export var swing_recover: float = 0.55
@export var swing_lunge_distance: float = 70.0
@export var swing_hitbox_extra: Vector2 = Vector2(40, 0)   # extension during swing

@onready var contact_hitbox: Area2D = get_node_or_null("ContactHitbox") as Area2D
@onready var contact_shape: CollisionShape2D = get_node_or_null("ContactHitbox/CollisionShape2D") as CollisionShape2D

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _state: int = 0     # 0 walk, 1 windup, 2 swing, 3 recover
var _state_timer: float = 0.0
var _swing_dir: Vector2 = Vector2.RIGHT
var _base_hitbox_offset: Vector2 = Vector2.ZERO
var _base_hitbox_size: Vector2 = Vector2(28, 28)


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	if contact_shape != null and contact_shape.shape is RectangleShape2D:
		_base_hitbox_size = (contact_shape.shape as RectangleShape2D).size
	if contact_hitbox != null:
		_base_hitbox_offset = contact_hitbox.position


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
	_state_timer -= delta

	match _state:
		0:
			# Walk toward player; trigger swing windup when in range.
			if dist <= swing_range:
				_start_windup((to_target.normalized() if dist > 0.1 else Vector2.RIGHT))
			else:
				velocity = velocity.move_toward(to_target.normalized() * walk_speed, acceleration * delta)
		1:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _state_timer <= 0.0:
				_start_swing()
		2:
			velocity = _swing_dir * (swing_lunge_distance / maxf(swing_duration, 0.01))
			if _state_timer <= 0.0:
				_end_swing()
		3:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if _state_timer <= 0.0:
				_state = 0

	move_and_slide()


func _start_windup(dir: Vector2) -> void:
	_state = 1
	_state_timer = windup_duration
	_swing_dir = dir
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.6, 0.6, 0.6, 1), windup_duration * 0.6)
		t.tween_property(sprite, "modulate", Color.WHITE, windup_duration * 0.4)


func _start_swing() -> void:
	_state = 2
	_state_timer = swing_duration
	# Extend the contact hitbox in the swing direction for the swing window.
	if contact_hitbox != null:
		contact_hitbox.position = _base_hitbox_offset + _swing_dir * 24.0
	if contact_shape != null and contact_shape.shape is RectangleShape2D:
		var s := (contact_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		s.size = _base_hitbox_size + swing_hitbox_extra
		contact_shape.shape = s


func _end_swing() -> void:
	_state = 3
	_state_timer = swing_recover
	if contact_hitbox != null:
		contact_hitbox.position = _base_hitbox_offset
	if contact_shape != null and contact_shape.shape is RectangleShape2D:
		var s := (contact_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		s.size = _base_hitbox_size
		contact_shape.shape = s


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
