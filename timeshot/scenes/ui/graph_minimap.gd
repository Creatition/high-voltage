extends Control
class_name GraphMinimap
## Procgen minimap. Draws DungeonRunner.layout as a 2D grid of cells, with the
## current cell highlighted and unexplored cells dimmed.
##
## Falls back to the legacy linear strip when DungeonRunner isn't active so
## the same widget can sit in the HUD across both modes.

@export var cell_size: Vector2 = Vector2(14, 14)
@export var cell_padding: float = 2.0
@export var unvisited_color: Color = Color(0.20, 0.20, 0.24)
@export var visited_color: Color = Color(0.65, 0.65, 0.70)
@export var current_color: Color = Color(1.0, 0.85, 0.30)
@export var boss_color: Color = Color(1.0, 0.40, 0.40)
@export var shop_color: Color = Color(0.45, 0.85, 1.00)
@export var shrine_color: Color = Color(0.55, 1.00, 0.45)
@export var secret_color: Color = Color(0.85, 0.45, 1.00)
@export var elite_color: Color = Color(1.00, 0.55, 0.30)
@export var corridor_color: Color = Color(0.30, 0.30, 0.36)


func _ready() -> void:
	var runner := get_node_or_null("/root/DungeonRunner")
	if runner != null:
		if runner.has_signal("room_entered"):
			runner.room_entered.connect(_on_room_entered.unbind(1))
		if runner.has_signal("dungeon_started"):
			runner.dungeon_started.connect(_on_dungeon_started.unbind(1))
	queue_redraw()


func _on_room_entered() -> void:
	queue_redraw()


func _on_dungeon_started() -> void:
	queue_redraw()


func _draw() -> void:
	var runner := get_node_or_null("/root/DungeonRunner")
	if runner == null or not runner.active or runner.layout == null:
		_draw_legacy_strip()
		return
	var layout = runner.layout
	for c in layout.cells.values():
		var color := _color_for_cell(c, runner.current_coord)
		var rect := Rect2(
			Vector2(c.coord.x, c.coord.y) * (cell_size + Vector2(cell_padding, cell_padding)),
			cell_size)
		draw_rect(rect, color, true)
		# Draw connection lines so corridors are visually obvious.
		for d in c.connections:
			var from := rect.position + cell_size * 0.5
			var to := from + Vector2(d.x, d.y) * (cell_size.x + cell_padding) * 0.5
			draw_line(from, to, color.darkened(0.2), 2.0)


func _color_for_cell(c: DungeonCell, current_coord: Vector2i) -> Color:
	if c.coord == current_coord:
		return current_color
	if not c.visited and c.type != DungeonCell.Type.START:
		return unvisited_color
	match c.type:
		DungeonCell.Type.BOSS:     return boss_color
		DungeonCell.Type.SHOP:     return shop_color
		DungeonCell.Type.SHRINE:   return shrine_color
		DungeonCell.Type.SECRET:   return secret_color
		DungeonCell.Type.ELITE:    return elite_color
		DungeonCell.Type.CORRIDOR: return corridor_color
	return visited_color


func _draw_legacy_strip() -> void:
	## Fallback for linear eras (Day 11+ migration still in progress).
	var queue: Array = GameState.dungeon_queue
	var idx := GameState.dungeon_index
	for i in queue.size():
		var pos := Vector2(i, 0) * (cell_size + Vector2(cell_padding, cell_padding))
		var rect := Rect2(pos, cell_size)
		var c := visited_color if i < idx else (current_color if i == idx else unvisited_color)
		var path := String(queue[i])
		if path.find("boss") != -1 and i != idx:
			c = boss_color.darkened(0.3) if i > idx else c
		draw_rect(rect, c, true)
