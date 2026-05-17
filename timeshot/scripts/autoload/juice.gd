extends Node
## Game-feel helpers: camera shake, hit-pause, white flashes.
## All public methods are no-ops if no Camera2D is current (e.g. menus).

@export var max_shake_offset: Vector2 = Vector2(8, 8)
@export var shake_decay: float = 6.0

var _shake_amount: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _hit_pause_remaining: float = 0.0
var _pre_pause_scale: float = 1.0


func _process(delta: float) -> void:
	# Decay shake; apply offset to current camera (if any).
	if _shake_amount > 0.0:
		_shake_amount = maxf(0.0, _shake_amount - shake_decay * delta)
		_shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * (max_shake_offset * _shake_amount)
	else:
		_shake_offset = Vector2.ZERO
	var cam := _find_camera()
	if cam != null:
		cam.offset = _shake_offset

	# Hit-pause uses unscaled engine time-scale, so count down with real-time delta.
	if _hit_pause_remaining > 0.0:
		# delta here is scaled; convert to wall-time approximation.
		var wall := delta / maxf(0.0001, Engine.time_scale)
		_hit_pause_remaining = maxf(0.0, _hit_pause_remaining - wall)
		if _hit_pause_remaining <= 0.0:
			Engine.time_scale = _pre_pause_scale


func shake(amount: float = 0.6) -> void:
	# amount is a 0–1 intensity; takes the max so quick re-hits don't shrink it.
	_shake_amount = clampf(maxf(_shake_amount, amount), 0.0, 1.0)


func hit_pause(duration: float = 0.05, scale: float = 0.0) -> void:
	if _hit_pause_remaining > 0.0:
		# Extend rather than stack.
		_hit_pause_remaining = maxf(_hit_pause_remaining, duration)
		return
	_pre_pause_scale = Engine.time_scale
	Engine.time_scale = scale
	_hit_pause_remaining = duration


func flash_sprite(sprite: Node, color: Color = Color(2.0, 2.0, 2.0, 1.0), duration: float = 0.06) -> void:
	if sprite == null or not sprite is CanvasItem:
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", color, 0.015)
	t.tween_property(sprite, "modulate", Color.WHITE, duration)


func _find_camera() -> Camera2D:
	var vp := get_viewport()
	if vp == null:
		return null
	return vp.get_camera_2d()
