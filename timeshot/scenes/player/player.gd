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


func _ready() -> void:
	if health != null:
		health.died.connect(_on_died)


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
	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position if muzzle != null else global_position
	if projectile.has_method("launch"):
		projectile.launch(_aim_direction)


func _on_died() -> void:
	# Placeholder — will hook into GameState.end_run() and trigger run-end UI.
	print("Player died")
	GameState.end_run("death")
