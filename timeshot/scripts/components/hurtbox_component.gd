extends Area2D
class_name HurtboxComponent
## Attach to anything that RECEIVES damage.
## Forwards hits to a HealthComponent on the same entity.

@export var health_component_path: NodePath
@export var team_id: int = 0   # entities with matching team_id ignore each other

var _health: HealthComponent


func _ready() -> void:
	if not health_component_path.is_empty():
		_health = get_node(health_component_path) as HealthComponent


func receive_hit(hitbox: HitboxComponent) -> void:
	if _health == null:
		return
	# Don't damage same-team entities (configurable later if needed).
	if hitbox.owner_id != 0 and hitbox.owner_id == team_id:
		return
	_health.take_damage(hitbox.damage)
