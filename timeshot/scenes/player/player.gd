extends CharacterBody2D
## Cas — the starter protagonist.
## Top-down twin-stick movement with dodge roll, aim, and shoot.

@export var move_speed: float = 220.0
@export var acceleration: float = 1800.0
@export var friction: float = 1600.0

@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.25
@export var dodge_cooldown: float = 0.6

@export var shoot_cooldown: float = 0.18
@export var projectile_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var health: HealthComponent = $HealthComponent

var _is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _shoot_cooldown_timer: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT

# Upgrade-modified runtime values (set by _apply_upgrades).
var _base_shoot_cooldown: float = 0.18
var _spread_extra_shots: int = 0       # extra side-shots; 0 = single bullet
var _spread_arc_degrees: float = 18.0
var _projectile_pierce: int = 0
var _projectile_bounces: int = 0
var _projectile_homing: float = 0.0
var _projectile_explosion: PackedScene = null


func _ready() -> void:
	add_to_group("players")
	if health != null:
		health.died.connect(_on_died)
		health.damaged.connect(_on_damaged)
	_base_shoot_cooldown = shoot_cooldown
	_apply_upgrades()
	# Listen for upgrades added mid-run so picking one in a shop refreshes the gun.
	if GameState.has_signal("upgrade_added"):
		GameState.upgrade_added.connect(_on_upgrade_added)


func _physics_process(delta: float) -> void:
	_dodge_cooldown_timer = maxf(0.0, _dodge_cooldown_timer - delta)
	_shoot_cooldown_timer = maxf(0.0, _shoot_cooldown_timer - delta)

	_update_aim()

	if _is_dodging:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			_end_dodge()
	else:
		_handle_movement(delta)
		if Input.is_action_just_pressed("dodge") and _dodge_cooldown_timer == 0.0:
			_start_dodge()
		if Input.is_action_pressed("shoot") and _shoot_cooldown_timer == 0.0:
			_shoot()

	move_and_slide()


func _handle_movement(delta: float) -> void:
	var input_vec := InputManager.get_move_vector()
	if input_vec.length_squared() > 0.0:
		velocity = velocity.move_toward(input_vec * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _update_aim() -> void:
	_aim_direction = InputManager.get_aim_vector(global_position, get_viewport())
	if sprite != null and _aim_direction.length_squared() > 0.0:
		# Flip sprite horizontally based on aim direction.
		sprite.flip_h = _aim_direction.x < 0
	if muzzle != null:
		muzzle.position = _aim_direction * 16.0   # 16px out from center


func _start_dodge() -> void:
	_is_dodging = true
	_dodge_timer = dodge_duration
	_dodge_cooldown_timer = dodge_cooldown
	var dodge_dir := velocity.normalized()
	if dodge_dir == Vector2.ZERO:
		dodge_dir = _aim_direction
	velocity = dodge_dir * dodge_speed
	if health != null:
		health.set_invulnerable_for(dodge_duration)


func _end_dodge() -> void:
	_is_dodging = false


func _shoot() -> void:
	_shoot_cooldown_timer = shoot_cooldown
	if projectile_scene == null:
		return
	var total_shots := 1 + _spread_extra_shots
	var arc := deg_to_rad(_spread_arc_degrees) * float(_spread_extra_shots)
	var start_angle := -arc * 0.5
	var step := 0.0
	if total_shots > 1:
		step = arc / float(total_shots - 1)
	for i in total_shots:
		var dir := _aim_direction.rotated(start_angle + step * float(i))
		_spawn_projectile(dir)


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position if muzzle != null else global_position
	# Apply upgrade-driven projectile modifiers if the script supports them.
	if "pierce" in projectile:
		projectile.pierce = _projectile_pierce
	if "bounces" in projectile:
		projectile.bounces = _projectile_bounces
	if "homing_strength" in projectile:
		projectile.homing_strength = _projectile_homing
	if "explosion_scene" in projectile:
		projectile.explosion_scene = _projectile_explosion
	if projectile.has_method("launch"):
		projectile.launch(direction)


func _apply_upgrades() -> void:
	# Reset to baseline before re-applying everything in GameState.run_upgrades.
	shoot_cooldown = _base_shoot_cooldown
	_spread_extra_shots = 0
	_projectile_pierce = 0
	_projectile_bounces = 0
	_projectile_homing = 0.0
	_projectile_explosion = null
	for upgrade_id in GameState.run_upgrades:
		_apply_upgrade(upgrade_id)


func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"fire_rate_1":
			shoot_cooldown = maxf(0.04, shoot_cooldown * 0.7)
		"shotgun_1":
			_spread_extra_shots += 2
		"bouncing_1":
			_projectile_bounces += 2
		"homing_1":
			_projectile_homing = maxf(_projectile_homing, 240.0)
			shoot_cooldown = shoot_cooldown * 1.15
		"explosive_1":
			_projectile_explosion = preload("res://scenes/projectiles/explosion.tscn")
		"pierce_1":
			_projectile_pierce += 1


func _on_damaged(_amount: int, _current: int, _max_value: int) -> void:
	# Hook for screen-shake / palette flash. No-op for the prototype.
	pass


func _on_upgrade_added(_upgrade_id: String) -> void:
	_apply_upgrades()


func _on_died() -> void:
	# Hook into GameState.end_run() and switch to the run-end UI when present.
	print("Player died")
	GameState.end_run("death")
	var run_end_path := "res://scenes/ui/run_end.tscn"
	if ResourceLoader.exists(run_end_path):
		get_tree().change_scene_to_file(run_end_path)
