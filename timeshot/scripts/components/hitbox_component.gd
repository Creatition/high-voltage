extends Area2D
class_name HitboxComponent
## Attach to anything that DEALS damage (bullets, melee swings, contact damage).
## Pair with a HurtboxComponent on the receiving entity.

@export var damage: int = 1
@export var knockback: float = 0.0
@export var owner_id: int = 0   # for friendly-fire filtering


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		area.receive_hit(self)
