extends StaticBody2D
class_name BreakableWall
## A wall segment that can be destroyed by player gunfire. When destroyed it
## emits broken and frees itself, revealing whatever's beyond — typically a
## secret room.
##
## The dungeon generator places these on the boundary between a room and its
## adjacent SECRET cell.

signal broken

@export var hp: int = 3
@export var debris_color: Color = Color(0.32, 0.28, 0.24)

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: ColorRect = $ColorRect

var _hp: int


func _ready() -> void:
	_hp = hp
	# Player projectiles call take_damage() via a generic hitbox protocol.


func take_damage(amount: int) -> void:
	_hp = maxi(0, _hp - amount)
	if _sprite != null:
		var t: float = float(_hp) / float(maxi(hp, 1))
		_sprite.modulate.a = clampf(0.4 + 0.6 * t, 0.0, 1.0)
	if _hp <= 0:
		_break()


func _break() -> void:
	broken.emit()
	# Small visual punch — modulate to debris colour then free.
	if _sprite != null:
		_sprite.color = debris_color
	if _shape != null:
		_shape.disabled = true
	queue_free()
