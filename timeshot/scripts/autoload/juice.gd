extends Node
## Game-feel helpers: camera shake, hit-pause, white flashes.
## All public methods are no-ops if no Camera2D is current (e.g. menus).

@export var max_shake_offset: Vector2 = Vector2(8, 8)
@export var shake_decay: float = 6.0
## Safety cap so a runaway hit-pause can never freeze the game for longer than
## this many seconds of wall time. Day-26 fix: previously the level-up picker
## paused the tree while a hit_pause was active, leaving Engine.time_scale
## stuck at 0.05 for ~picker_open_duration of wall time. The pause uses real
## time now (not delta) so it can't get stuck, and the cap is a belt-and-suspenders.
@export var hit_pause_max_seconds: float = 0.25

var _shake_amount: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _hit_pause_active: bool = false
var _hit_pause_end_msec: int = 0           ## Wall-time deadline in ms (Time.get_ticks_msec)
var _pre_pause_scale: float = 1.0


func _ready() -> void:
	# PROCESS_MODE_ALWAYS so we keep ticking down hit-pause / clearing camera
	# shake even when get_tree().paused is true (e.g. while the upgrade picker
	# is open). Without this, time_scale could leak past the picker and the
	# game would resume in 5%-speed slow-mo with active screen shake, which
	# reads to the player as "frozen / screen shaking, can't move".
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	# Use unscaled wall-clock time for everything so Engine.time_scale tricks
	# (slow-mo on player damage) can never starve the shake decay or the
	# hit-pause countdown.
	var now_msec: int = Time.get_ticks_msec()

	# Shake: decay using real seconds since the last frame. We approximate with
	# a tiny fixed dt to avoid drift; precise enough for a visual juice effect.
	if _shake_amount > 0.0:
		_shake_amount = maxf(0.0, _shake_amount - shake_decay * 0.016)
		_shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * (max_shake_offset * _shake_amount)
	else:
		_shake_offset = Vector2.ZERO
	var cam := _find_camera()
	if cam != null:
		cam.offset = _shake_offset

	# Hit-pause: ends purely on wall-time deadline. Belt-and-suspenders restore
	# of time_scale runs at the deadline AND if anyone's left _pre_pause_scale
	# at something weird, we force-clamp to 1.0 as a final fallback.
	if _hit_pause_active and now_msec >= _hit_pause_end_msec:
		_hit_pause_active = false
		Engine.time_scale = _pre_pause_scale if _pre_pause_scale > 0.0 else 1.0


func shake(amount: float = 0.6) -> void:
	# amount is a 0-1 intensity; takes the max so quick re-hits don't shrink it.
	_shake_amount = clampf(maxf(_shake_amount, amount), 0.0, 1.0)


func hit_pause(duration: float = 0.05, scale: float = 0.0) -> void:
	# Clamp duration so a misconfigured caller can't ever stall the game.
	var dur: float = clampf(duration, 0.0, hit_pause_max_seconds)
	var deadline: int = Time.get_ticks_msec() + int(dur * 1000.0)
	if _hit_pause_active:
		# Extend (take max deadline) without re-snapshotting _pre_pause_scale,
		# so the first call's pre-scale wins and a subsequent slow call can't
		# accidentally lock us at slow-mo.
		_hit_pause_end_msec = maxi(_hit_pause_end_msec, deadline)
		Engine.time_scale = scale
		return
	# First entry: snapshot the CURRENT scale only if it looks sane (>0); if
	# someone left time_scale at 0 we'd otherwise restore to 0 forever.
	var snap: float = Engine.time_scale
	_pre_pause_scale = snap if snap > 0.0 else 1.0
	Engine.time_scale = scale
	_hit_pause_end_msec = deadline
	_hit_pause_active = true


func reset_time_and_shake() -> void:
	## Defensive utility for screens that pause the tree (upgrade picker,
	## pause menu, run-end) so an in-flight juice effect can't bleed into
	## the gameplay frame after the screen closes.
	_hit_pause_active = false
	_shake_amount = 0.0
	_shake_offset = Vector2.ZERO
	Engine.time_scale = 1.0
	var cam := _find_camera()
	if cam != null:
		cam.offset = Vector2.ZERO


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
