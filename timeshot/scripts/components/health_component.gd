extends Node
class_name HealthComponent
## Attach to any entity that can take damage.
## Emits signals on damage/heal/death.

@export var max_hp: int = 10
@export var invuln_after_hit: float = 0.0   # seconds of i-frames after taking damage

var current_hp: int
var _invuln_until: float = 0.0

signal damaged(amount: int, current: int, max_value: int)
signal healed(amount: int, current: int, max_value: int)
signal died


func _ready() -> void:
	current_hp = max_hp


func is_alive() -> bool:
	return current_hp > 0


func is_invulnerable() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _invuln_until


func take_damage(amount: int) -> bool:
	if not is_alive() or is_invulnerable():
		return false
	current_hp = maxi(0, current_hp - amount)
	damaged.emit(amount, current_hp, max_hp)
	if invuln_after_hit > 0.0:
		_invuln_until = Time.get_ticks_msec() / 1000.0 + invuln_after_hit
	if current_hp == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if not is_alive():
		return
	current_hp = mini(max_hp, current_hp + amount)
	healed.emit(amount, current_hp, max_hp)


func set_invulnerable_for(seconds: float) -> void:
	_invuln_until = max(_invuln_until, Time.get_ticks_msec() / 1000.0 + seconds)
