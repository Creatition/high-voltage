extends Area2D
class_name RewardShrine
## Walk-up interaction prop. When the player overlaps and presses Interact,
## it opens the upgrade picker once, then despawns.
##
## Drop into any room scene to gate an upgrade reward behind a clear condition
## (e.g. "after the wave is dead, this becomes interactable").

@export var picker_scene: PackedScene = preload("res://scenes/ui/upgrade_picker.tscn")
@export var era: String = "any"
@export var requires_room_clear: bool = false

@onready var _label: Label = $Label
@onready var _glow: ColorRect = $Glow

var _player_in_range: bool = false
var _consumed: bool = false
var _enabled: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if requires_room_clear:
		set_enabled(false)
	else:
		set_enabled(true)


func _process(_delta: float) -> void:
	if not _enabled or _consumed:
		_label.visible = false
		return
	_label.visible = _player_in_range
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_open()


func set_enabled(value: bool) -> void:
	_enabled = value
	modulate = Color(1, 1, 1, 1) if value else Color(0.4, 0.4, 0.4, 0.5)


func _open() -> void:
	if _consumed:
		return
	_consumed = true
	var picker := picker_scene.instantiate()
	get_tree().current_scene.add_child(picker)
	if picker.has_method("open"):
		picker.open(era)
	if picker.has_signal("closed"):
		picker.closed.connect(_on_picker_closed)


func _on_picker_closed(_picked_id: String) -> void:
	# Visual feedback: dim and hide the prompt; queue free shortly.
	if _glow != null:
		_glow.modulate = Color(0.3, 0.3, 0.3, 0.6)
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(queue_free)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = false
