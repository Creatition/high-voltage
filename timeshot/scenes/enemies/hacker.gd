extends EnemyBase
class_name Hacker
## Cyberpunk support enemy. Stays at very long range and periodically casts
## a "Boost" pulse — a brief visual ring that grants every other enemy in
## the room a temporary projectile speed + fire rate buff.
##
## Kill priority. Modest HP, no damaging projectile of its own.

@export var move_speed: float = 60.0
@export var acceleration: float = 240.0
@export var preferred_distance: float = 420.0
@export var distance_tolerance: float = 60.0

@export var pulse_cooldown: float = 4.0
@export var first_pulse_delay: float = 1.5
@export var buff_duration: float = 3.0
@export var buff_speed_mult: float = 1.35
@export var buff_cooldown_mult: float = 0.7

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _pulse_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_pulse_timer = first_pulse_delay


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	if _target != null:
		var to_target := _target.global_position - global_position
		var dist := to_target.length()
		if dist > preferred_distance + distance_tolerance:
			velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
		elif dist < preferred_distance - distance_tolerance:
			velocity = velocity.move_toward(-to_target.normalized() * move_speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	move_and_slide()

	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_emit_buff_pulse()
		_pulse_timer = pulse_cooldown


func _emit_buff_pulse() -> void:
	# Visual: brief expanding ring (a sprite scale tween).
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.6, 0.6, 1.6, 1), 0.15)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	# Apply buff to nearby enemies (excluding self).
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		# Buff projectile speed / shoot cooldown if those properties exist.
		if "projectile_speed" in e:
			e.set("projectile_speed", float(e.get("projectile_speed")) * buff_speed_mult)
		if "shoot_cooldown" in e:
			e.set("shoot_cooldown", float(e.get("shoot_cooldown")) * buff_cooldown_mult)
		# Schedule revert.
		_revert_buff_later(e, e.get("projectile_speed"), e.get("shoot_cooldown"))


func _revert_buff_later(enemy: Node, _orig_speed: Variant, _orig_cd: Variant) -> void:
	# Capture and revert by reversing the multipliers (idempotent enough for
	# the prototype — multiple stacks decay symmetrically).
	await get_tree().create_timer(buff_duration).timeout
	if not is_instance_valid(enemy):
		return
	if "projectile_speed" in enemy:
		enemy.set("projectile_speed", float(enemy.get("projectile_speed")) / buff_speed_mult)
	if "shoot_cooldown" in enemy:
		enemy.set("shoot_cooldown", float(enemy.get("shoot_cooldown")) / buff_cooldown_mult)


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
