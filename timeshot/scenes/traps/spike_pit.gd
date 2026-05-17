extends Node2D
class_name SpikePit
## Telegraphed pop-up spikes. Cycles through three states forever:
##   IDLE    -> visible flat tile, no damage
##   WARN    -> brief flash/expansion telegraph, no damage yet
##   ACTIVE  -> spikes are out, deals damage to anything overlapping a child
##              HitboxComponent (set up to hit player hurtbox layer L4).
##
## Designers can:
##   - Stagger many spikes via `phase_offset` so a corridor pulses in waves.
##   - Set `armed` to false to let a PressurePlate enable a normally-dormant pit.

@export var idle_duration: float = 1.6
@export var warn_duration: float = 0.45
@export var active_duration: float = 0.55
@export var phase_offset: float = 0.0
@export var damage: int = 2
@export var armed: bool = true

@onready var _base: ColorRect = $Base
@onready var _spikes: ColorRect = $Spikes
@onready var _hitbox: Area2D = $Hitbox
@onready var _hit_shape: CollisionShape2D = $Hitbox/CollisionShape2D

const COLOR_IDLE := Color(0.20, 0.20, 0.24, 1.0)
const COLOR_WARN := Color(0.95, 0.65, 0.20, 0.85)
const COLOR_ACTIVE := Color(0.95, 0.30, 0.30, 1.0)

enum State { IDLE, WARN, ACTIVE }
var _state: int = State.IDLE
var _state_timer: float = 0.0


func _ready() -> void:
	_hit_shape.disabled = true
	_state_timer = -phase_offset
	_enter(State.IDLE)


func set_armed(value: bool) -> void:
	armed = value
	if not armed:
		_enter(State.IDLE)


func _physics_process(delta: float) -> void:
	if not armed:
		return
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	match _state:
		State.IDLE:
			_enter(State.WARN)
		State.WARN:
			_enter(State.ACTIVE)
		State.ACTIVE:
			_enter(State.IDLE)


func _enter(new_state: int) -> void:
	_state = new_state
	match _state:
		State.IDLE:
			_state_timer = idle_duration
			_spikes.visible = false
			_base.color = COLOR_IDLE
			_hit_shape.disabled = true
		State.WARN:
			_state_timer = warn_duration
			_spikes.visible = false
			_base.color = COLOR_WARN
			_hit_shape.disabled = true
		State.ACTIVE:
			_state_timer = active_duration
			_spikes.visible = true
			_base.color = COLOR_ACTIVE
			_hit_shape.disabled = false
