extends Area2D
class_name Door
## Door that, when the player walks into it (and it's unlocked), advances
## the dungeon to the next room.
##
## next_scene_path can be empty: in that case the door asks the active
## DungeonRunner autoload (if present) what comes next; otherwise it does
## nothing.

@export var next_scene_path: String = ""
@export var locked_color: Color = Color(0.45, 0.2, 0.2, 1.0)
@export var unlocked_color: Color = Color(0.35, 0.85, 0.45, 1.0)

@onready var _sprite: ColorRect = $ColorRect
@onready var _label: Label = $Label

var _is_locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual()


func set_locked(locked: bool) -> void:
	_is_locked = locked
	_apply_visual()


func is_locked() -> bool:
	return _is_locked


func _apply_visual() -> void:
	if _sprite != null:
		_sprite.color = locked_color if _is_locked else unlocked_color
	if _label != null:
		_label.text = "LOCKED" if _is_locked else "EXIT"


func _on_body_entered(body: Node) -> void:
	if _is_locked or not body.is_in_group("players"):
		return
	_advance()


func _advance() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("door", -6.0)
	# Boss Rush: always step through GameState.dungeon_queue regardless of
	# the door's hardcoded next_scene_path (so era boss rooms can be reused).
	if GameState.current_era == "boss_rush" and GameState.has_method("next_room_path"):
		var next: String = GameState.next_room_path()
		if next != "" and ResourceLoader.exists(next):
			get_tree().change_scene_to_file(next)
			return
		# Boss rush complete → run-end screen.
		GameState.end_run("victory")
		get_tree().change_scene_to_file("res://scenes/ui/run_end.tscn")
		return
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
		return
	# Fallback: ask GameState what's next.
	if GameState.has_method("next_room_path"):
		var path: String = GameState.next_room_path()
		if path != "":
			get_tree().change_scene_to_file(path)
