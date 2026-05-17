extends EnemyBase
class_name SwarmerEnemy
## Fast weak melee mob that flanks the player by orbiting toward them rather
## than driving straight in. Travels in small groups; individual swarmers are
## fragile but they collectively force you to keep moving.

@export var move_speed: float = 165.0
@export var acceleration: float = 900.0
@export var aggro_radius: float = 900.0
@export var flank_strength: float = 0.45

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _flank_dir: float = 1.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	# Half flank left, half flank right — looks more like a real swarm.
	_flank_dir = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.4

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	if dist > aggro_radius:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	else:
		# Blend a perpendicular "flank" vector into the chase direction so the
		# swarmer curves around the player.
		var chase := to_target.normalized()
		var flank := Vector2(-chase.y, chase.x) * _flank_dir
		var desired := (chase + flank * flank_strength).normalized() * move_speed
		velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()


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
