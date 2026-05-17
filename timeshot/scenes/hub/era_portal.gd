extends Area2D
class_name EraPortal
## Walk-up portal in the time machine hub. When the player interacts,
## it tells GameState to start an era and switches scenes to that era's
## first room.

@export var era_id: String = "present"
@export var era_label: String = "Present"
## PackedStringArray of res:// paths to load in order. First element is the
## room the player drops into when they take the portal.
@export var room_queue: PackedStringArray = PackedStringArray()
@export var color: Color = Color(0.4, 0.8, 1.0, 1.0)
@export var unlocked: bool = true

@onready var _label: Label = $Label
@onready var _prompt: Label = $Prompt
@onready var _ring: ColorRect = $Ring

var _player_in_range: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_label.text = era_label
	_ring.color = color if unlocked else Color(0.3, 0.3, 0.35, 1.0)


func _process(_delta: float) -> void:
	_prompt.visible = _player_in_range and unlocked
	if _player_in_range and unlocked and Input.is_action_just_pressed("interact"):
		_enter()


func _enter() -> void:
	if room_queue.is_empty():
		return
	var queue: Array = []
	for p in room_queue:
		queue.append(p)
	GameState.start_era(era_id, queue)
	get_tree().change_scene_to_file(room_queue[0])


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("players"):
		_player_in_range = false
