extends Area2D
class_name Explosion
## A short-lived expanding circle that damages anything in its hurtbox layer
## via a child HitboxComponent during a single "tick" window.

@export var radius: float = 56.0
@export var damage: int = 2
@export var duration: float = 0.18
@export var hits_players: bool = false   # true for enemy explosions

var _life: float = 0.0
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: HitboxComponent = $HitboxComponent
@onready var _hitshape: CollisionShape2D = $HitboxComponent/CollisionShape2D


func _ready() -> void:
	# Configure circle shapes by radius at runtime so designers can tweak via export.
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = radius
	_hitshape.shape = hit_circle
	_hitbox.damage = damage
	# Default explosion is from a player projectile -> hits enemy hurtboxes (L5).
	# Friendly-fire safety: enemy variants should set hits_players=true at spawn time.
	if hits_players:
		_hitbox.collision_layer = 64
		_hitbox.collision_mask = 8
		_hitbox.owner_id = 2
	else:
		_hitbox.collision_layer = 32
		_hitbox.collision_mask = 16
		_hitbox.owner_id = 1
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.7, 0.25, 1.0)


func _process(delta: float) -> void:
	_life += delta
	var t := clampf(_life / duration, 0.0, 1.0)
	if _sprite != null:
		_sprite.scale = Vector2.ONE * (0.4 + t * 1.6)
		_sprite.modulate.a = 1.0 - t
	if _life >= duration:
		queue_free()
