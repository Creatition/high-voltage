extends Node2D
class_name DartShooter
## Fires a single enemy-projectile periodically along a configurable direction.
## Direction defaults to +X; rotate the node in the scene to change it.
##
## Modes:
##   - When `auto_fire` is true (default), shoots every `interval` seconds.
##   - When `auto_fire` is false, a PressurePlate (or any other script) calls
##     fire_once() to make it shoot exactly once.

@export var auto_fire: bool = true
@export var interval: float = 1.4
@export var startup_delay: float = 0.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/enemy_projectile.tscn")

@onready var _muzzle: Marker2D = $Muzzle

var _timer: float = 0.0


func _ready() -> void:
	_timer = startup_delay


func _process(delta: float) -> void:
	if not auto_fire:
		return
	_timer -= delta
	if _timer <= 0.0:
		fire_once()
		_timer = interval


func fire_once() -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	# Spawn at the muzzle position so designers can offset the dart from the
	# wall the shooter is embedded in.
	proj.global_position = _muzzle.global_position if _muzzle != null else global_position
	if proj.has_method("launch"):
		var dir := Vector2.RIGHT.rotated(global_rotation)
		proj.launch(dir)
