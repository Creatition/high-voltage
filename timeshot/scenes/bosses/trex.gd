extends EnemyBase
class_name TRex
## Prehistoric boss. Patterns:
##   0: Chomp lunge — telegraphs then dashes ~280px toward player, extended contact hitbox.
##   1: Stomp shockwave — pauses and emits a slow expanding ring of projectiles.
##   2: Roar spawn — calls 3 raptors to harass.
##
## When enraged (<40% HP), phase_duration shortens and dash speed scales up.

@export var move_speed: float = 90.0
@export var acceleration: float = 320.0
@export var preferred_distance: float = 180.0

@export var phase_duration: float = 3.2
@export var lunge_charge: float = 0.55
@export var lunge_speed: float = 460.0
@export var lunge_duration: float = 0.45
@export var ring_count: int = 16
@export var raptor_spawn_count: int = 3
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")
@export var raptor_scene: PackedScene = preload("res://scenes/enemies/raptor.tscn")

var _target: Node2D = null
var _retarget_timer: float = 0.0
var _phase: int = 0
var _phase_timer: float = 0.0
var _enraged: bool = false
var _busy: bool = false   # while running a multi-step pattern


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bosses")
	_phase_timer = phase_duration
	if health != null:
		health.damaged.connect(_check_enrage)


func _check_enrage(_amount: int, current: int, max_value: int) -> void:
	if _enraged:
		return
	if float(current) / float(maxi(1, max_value)) <= 0.4:
		_enraged = true
		phase_duration *= 0.7
		lunge_speed *= 1.2
		if sprite != null:
			var t := create_tween()
			t.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1), 0.15)
			t.tween_property(sprite, "modulate", Color.WHITE, 0.35)


func _physics_process(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target):
		_retarget()
		_retarget_timer = 0.6

	if not _busy:
		_chase(delta)
	move_and_slide()

	if not _busy:
		_phase_timer -= delta
		if _phase_timer <= 0.0:
			_run_phase()
			_phase = (_phase + 1) % 3
			_phase_timer = phase_duration


func _chase(delta: float) -> void:
	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		return
	var to_target := _target.global_position - global_position
	if to_target.length() > preferred_distance:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)


func _run_phase() -> void:
	match _phase:
		0:
			_chomp_lunge()
		1:
			_stomp_ring()
		2:
			_roar_spawn()


func _chomp_lunge() -> void:
	if _target == null:
		return
	_busy = true
	var dir := (_target.global_position - global_position).normalized()
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.6, 0.6, 0.4, 1), lunge_charge * 0.8)
		t.tween_property(sprite, "modulate", Color.WHITE, lunge_charge * 0.2)
	await get_tree().create_timer(lunge_charge).timeout
	if not is_instance_valid(self):
		return
	# Drive velocity briefly. Yield back each frame.
	var start_time := Time.get_ticks_msec()
	while is_instance_valid(self) and float(Time.get_ticks_msec() - start_time) / 1000.0 < lunge_duration:
		velocity = dir * lunge_speed
		await get_tree().physics_frame
	_busy = false


func _stomp_ring() -> void:
	_busy = true
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1.4, 1.4, 0.6, 1), 0.35)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self):
		return
	var step := TAU / float(ring_count)
	for i in ring_count:
		_spawn_proj(Vector2.RIGHT.rotated(step * float(i)), 200.0)
	_busy = false


func _roar_spawn() -> void:
	if raptor_scene == null:
		return
	_busy = true
	if sprite != null:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(2.0, 0.7, 0.3, 1), 0.25)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self):
		return
	for i in raptor_spawn_count:
		var angle := randf() * TAU
		var offset := Vector2.RIGHT.rotated(angle) * 90.0
		var r := raptor_scene.instantiate()
		get_tree().current_scene.add_child(r)
		r.global_position = global_position + offset
	_busy = false


func _spawn_proj(dir: Vector2, spd: float) -> void:
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if "speed" in proj:
		proj.speed = spd
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
