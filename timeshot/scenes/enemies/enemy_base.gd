extends CharacterBody2D
class_name EnemyBase
## Base class for all enemies. Wires up damage flash, death, and
## currency drop on kill. Subclasses add AI in _physics_process.

@export var currency_on_death: int = 1
@export var flash_color: Color = Color(1.5, 1.5, 1.5, 1.0)
@export var flash_duration: float = 0.08

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var health: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent

var _flash_tween: Tween


func _ready() -> void:
	if health != null:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)


func _on_damaged(_amount: int, _current: int, _max_value: int) -> void:
	_flash()


func _flash() -> void:
	if sprite == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)


func _on_died() -> void:
	if currency_on_death > 0:
		GameState.add_currency(currency_on_death)
	# Brief death feedback then despawn.
	if sprite != null:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		tween.tween_callback(queue_free)
	else:
		queue_free()
