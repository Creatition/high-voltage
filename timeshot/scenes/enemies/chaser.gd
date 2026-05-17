extends EnemyBase
class_name ChaserEnemy
## Walks straight at the nearest player. Deals contact damage via a HitboxComponent.
## Designed for the prototype Present era.

@export var move_speed: float = 130.0
@export var acceleration: float = 700.0
@export var aggro_radius: float = 800.0

var _target: Node2D = null
var _retarget_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.5

	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	else:
		var to_target := (_target.global_position - global_position)
		if to_target.length() > aggro_radius:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		else:
			velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
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
