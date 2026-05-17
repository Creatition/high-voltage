extends Area2D
## Basic projectile. Travels in a launched direction, despawns on lifetime or collision.

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: int = 1

var _direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func launch(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += _direction * speed * delta


func _on_body_entered(_body: Node) -> void:
	# Hit a wall / solid body. Despawn.
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Pass through HitboxComponents (those exist on enemies/etc., the bullet IS one).
	# This branch handles overlapping with a HurtboxComponent on a hittable entity.
	if area is HurtboxComponent:
		# In a fuller setup, this bullet would have its own HitboxComponent child
		# and the hurtbox would handle the damage. For the stub, deal damage directly.
		var hurtbox := area as HurtboxComponent
		var health_node := hurtbox.get_node_or_null(hurtbox.health_component_path) as HealthComponent
		if health_node != null:
			health_node.take_damage(damage)
		queue_free()
