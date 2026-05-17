extends EnemyBase
class_name BomberEnemy
## Slow chunky enemy that walks toward the player and detonates on contact or
## on death. The explosion is the threat — its contact hitbox is light.

@export var move_speed: float = 70.0
@export var acceleration: float = 350.0
@export var aggro_radius: float = 700.0
@export var detonate_radius: float = 60.0
@export var detonate_charge: float = 0.5
@export var explosion_scene: PackedScene = preload("res://scenes/projectiles/explosion.tscn")

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _charging: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.5

	if _charging or _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	if dist <= detonate_radius:
		_start_detonation()
	elif dist <= aggro_radius:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	move_and_slide()


func _start_detonation() -> void:
	if _charging:
		return
	_charging = true
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1), detonate_charge * 0.8)
		t.tween_property(sprite, "modulate", Color.WHITE, detonate_charge * 0.2)
	await get_tree().create_timer(detonate_charge).timeout
	if is_instance_valid(self):
		_detonate()


func _detonate() -> void:
	# Self-destruct path (contact detonation). Spawn boom and free ourselves.
	_spawn_boom()
	queue_free()


func _spawn_boom() -> void:
	if explosion_scene == null:
		return
	var boom := explosion_scene.instantiate()
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position


func _on_died() -> void:
	# Killed by player damage — drop a boom, then let EnemyBase handle the
	# usual currency / shrink tween / queue_free. _charging blocks the
	# contact-detonation path from spawning a second boom in parallel.
	if not _charging:
		_charging = true
		_spawn_boom()
	super._on_died()


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
