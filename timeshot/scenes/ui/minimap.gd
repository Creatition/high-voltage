extends Control
class_name Minimap
## Tiny per-run room progress strip. Draws a dot for each entry in
## GameState.dungeon_queue, lit-up for visited rooms, golden for the boss.
##
## Updates when the GameState `era_changed` signal fires (era start) and on
## scene enter (constructor — picks up dungeon_index changes too).

@export var dot_size: Vector2 = Vector2(14, 14)
@export var spacing: float = 8.0
@export var unvisited_color: Color = Color(0.25, 0.25, 0.30)
@export var visited_color: Color = Color(1.0, 0.85, 0.3)
@export var current_color: Color = Color(0.4, 1.0, 0.45)
@export var boss_color: Color = Color(1.0, 0.35, 0.40)

@onready var _row: HBoxContainer = $Row
@onready var _label: Label = $Label


func _ready() -> void:
	if GameState.has_signal("era_changed"):
		GameState.era_changed.connect(_refresh.unbind(1))
	_refresh()


func _refresh() -> void:
	for c in _row.get_children():
		c.queue_free()
	var queue: Array = GameState.dungeon_queue
	var idx := GameState.dungeon_index
	for i in queue.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = dot_size
		var path := String(queue[i])
		var is_boss := path.find("_boss") != -1 or path.find("boss") != -1
		if i < idx:
			dot.color = visited_color
		elif i == idx:
			dot.color = current_color
		elif is_boss:
			dot.color = boss_color
		else:
			dot.color = unvisited_color
		_row.add_child(dot)
	var era := GameState.current_era
	_label.text = "%s  —  room %d / %d" % [era.capitalize(), mini(idx + 1, maxi(queue.size(), 1)), maxi(queue.size(), 1)]
