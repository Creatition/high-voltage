extends Control
class_name GungeonMinimap
## Day 4 of the Gungeon-style dungeon pass.
##
## Renders the dungeon the way Enter the Gungeon does in the reference image:
##  - Each multi-cell room is drawn as one rounded rectangle (no internal walls)
##  - Corridor cells are drawn as thin slate-grey lines linking room edges
##  - Special rooms wear an icon: skull (BOSS), $ (SHOP), star (SHRINE),
##    ? (SECRET), spark (ELITE), and the player's current room blinks brighter
##  - Unvisited rooms render in a darker shade; the boss room is hinted in red
##    once the player has been adjacent to it
##
## The widget is fully self-contained: it reads DungeonRunner.layout and
## reconstructs multi-cell room groupings from each DungeonCell's template_id
## (encoded by GungeonLayoutBuilder as "groom:<id>:<shape>:<type>"). If the
## current dungeon isn't a gungeon-style layout, the widget falls back to a
## simple legacy grid render so it can sit in the HUD across both pipelines.

@export var cell_size: Vector2 = Vector2(16, 16)
@export var cell_gap: Vector2 = Vector2(2, 2)
@export var room_corner_radius: float = 3.0
@export var room_padding: float = 1.0           ## Visual inset so adjacent rooms don't touch
@export var corridor_thickness: float = 3.0

@export_group("Colors")
@export var unvisited_color: Color = Color(0.16, 0.18, 0.26)
@export var visited_color: Color = Color(0.38, 0.42, 0.58)
@export var current_color: Color = Color(1.00, 0.86, 0.30)
@export var border_color: Color = Color(0.78, 0.80, 0.88)
@export var corridor_color: Color = Color(0.30, 0.34, 0.46)
@export var boss_color: Color = Color(0.85, 0.30, 0.30)
@export var shop_color: Color = Color(0.40, 0.78, 0.95)
@export var shrine_color: Color = Color(0.55, 0.95, 0.55)
@export var elite_color: Color = Color(0.95, 0.55, 0.30)
@export var secret_color: Color = Color(0.80, 0.45, 0.95)

@export_group("Icons")
@export var icon_font_size: int = 12
@export var draw_icons: bool = true

var _icon_font: Font = null


func _ready() -> void:
	_icon_font = ThemeDB.fallback_font
	var runner: Node = get_node_or_null("/root/DungeonRunner")
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
	var runner: Node = get_node_or_null("/root/DungeonRunner")
	if runner == null or not runner.active or runner.layout == null:
		_draw_legacy_placeholder()
		return
	var layout: DungeonLayout = runner.layout
	var current_coord: Vector2i = runner.current_coord

	# Reconstruct multi-cell room groupings from cell template ids.
	var groups: Dictionary = _group_cells_by_room_id(layout)
	if groups.is_empty():
		# Not a gungeon-style layout — fall back to one rect per cell.
		_draw_per_cell(layout, current_coord)
		return

	# Pass 1: corridors first so room outlines sit on top.
	_draw_corridors(layout, current_coord)
	# Pass 2: room rectangles + icons.
	for room_id in groups.keys():
		_draw_room_group(groups[room_id], current_coord)


# -------------------------------------------------------------------------
# Multi-cell room rendering
# -------------------------------------------------------------------------

func _group_cells_by_room_id(layout: DungeonLayout) -> Dictionary:
	## room_id -> {cells: Array[DungeonCell], type: int, shape_id: String}
	var groups: Dictionary = {}
	for c in layout.cells.values():
		if c.type == DungeonCell.Type.CORRIDOR:
			continue
		var meta: Dictionary = GungeonLayoutBuilder.decode_room_template_id(c.template_id)
		if meta.is_empty():
			# Legacy / un-gungeon cell — emit a per-cell pseudo-room.
			var key: String = "legacy_%d_%d" % [c.coord.x, c.coord.y]
			groups[key] = {"cells": [c], "type": c.type, "shape_id": "1x1"}
			continue
		var rid: int = meta["room_id"]
		if not groups.has(rid):
			groups[rid] = {"cells": [], "type": c.type, "shape_id": meta["shape_id"]}
		groups[rid]["cells"].append(c)
		# In a multi-cell room, every cell carries the room's type — but if
		## the START room overrode just one cell we want the room type to be
		## START. Prefer non-NORMAL types.
		if c.type != DungeonCell.Type.NORMAL and c.type != DungeonCell.Type.EMPTY:
			groups[rid]["type"] = c.type
	return groups


func _draw_room_group(group: Dictionary, current_coord: Vector2i) -> void:
	var cells: Array = group["cells"]
	if cells.is_empty():
		return
	# Compute bounds in cell-space, then in pixel-space.
	var min_c: Vector2i = (cells[0] as DungeonCell).coord
	var max_c: Vector2i = min_c
	var any_visited: bool = false
	var any_current: bool = false
	for c in cells:
		var co: Vector2i = (c as DungeonCell).coord
		min_c.x = mini(min_c.x, co.x)
		min_c.y = mini(min_c.y, co.y)
		max_c.x = maxi(max_c.x, co.x)
		max_c.y = maxi(max_c.y, co.y)
		if (c as DungeonCell).visited:
			any_visited = true
		if co == current_coord:
			any_current = true
	var top_left: Vector2 = _cell_to_pixel(min_c) + Vector2(room_padding, room_padding)
	var bottom_right: Vector2 = _cell_to_pixel(max_c) + cell_size - Vector2(room_padding, room_padding)
	var rect: Rect2 = Rect2(top_left, bottom_right - top_left)

	var type: int = group["type"]
	var fill: Color = _fill_for(type, any_visited, any_current)
	_draw_rounded_rect(rect, fill, room_corner_radius)
	_draw_rounded_outline(rect, border_color, room_corner_radius, 1.5)

	if draw_icons and any_visited:
		_draw_room_icon(rect, type)


func _draw_corridors(layout: DungeonLayout, current_coord: Vector2i) -> void:
	## Draw thin lines through any CORRIDOR cell and across any direct
	## inter-room shared-wall connection (so EtG-style stub corridors and
	## flush doors both read clearly on the map).
	for c in layout.cells.values():
		if c.type == DungeonCell.Type.CORRIDOR:
			var centre: Vector2 = _cell_centre(c.coord)
			var col: Color = corridor_color
			if c.visited:
				col = corridor_color.lightened(0.2)
			for d in c.connections:
				var nbr_centre: Vector2 = _cell_centre(c.coord + d)
				draw_line(centre, nbr_centre, col, corridor_thickness)
		# Shared-wall door — render a tiny tick where two different rooms
		# meet so the player can see which walls have doors.
		var meta_self: Dictionary = GungeonLayoutBuilder.decode_room_template_id(c.template_id)
		if meta_self.is_empty():
			continue
		for d in c.connections:
			var nb_coord: Vector2i = c.coord + d
			var nb: DungeonCell = layout.cells.get(nb_coord, null)
			if nb == null or nb.type == DungeonCell.Type.CORRIDOR:
				continue
			var meta_nb: Dictionary = GungeonLayoutBuilder.decode_room_template_id(nb.template_id)
			if meta_nb.is_empty() or meta_nb["room_id"] == meta_self["room_id"]:
				continue
			# Different rooms sharing a wall — draw a small door tick.
			var mid: Vector2 = (_cell_centre(c.coord) + _cell_centre(nb_coord)) * 0.5
			var perp: Vector2 = Vector2(-d.y, d.x)
			var visible: bool = c.visited or nb.visited
			var col: Color = border_color if visible else unvisited_color.lightened(0.3)
			draw_line(mid - perp * 3.0, mid + perp * 3.0, col, 2.0)


# -------------------------------------------------------------------------
# Legacy / per-cell fallback render
# -------------------------------------------------------------------------

func _draw_per_cell(layout: DungeonLayout, current_coord: Vector2i) -> void:
	for c in layout.cells.values():
		var col: Color = _fill_for(c.type, c.visited, c.coord == current_coord)
		var pos: Vector2 = _cell_to_pixel(c.coord)
		draw_rect(Rect2(pos, cell_size), col, true)
		for d in c.connections:
			var here: Vector2 = pos + cell_size * 0.5
			var there: Vector2 = here + Vector2(d.x, d.y) * (cell_size.x + cell_gap.x) * 0.5
			draw_line(here, there, col.darkened(0.25), 2.0)


func _draw_legacy_placeholder() -> void:
	## Nothing to draw — the old GraphMinimap handles that case. Leaving this
	## blank keeps the widget invisible when stacked behind the legacy minimap.
	pass


# -------------------------------------------------------------------------
# Drawing primitives
# -------------------------------------------------------------------------

func _draw_rounded_rect(rect: Rect2, color: Color, radius: float) -> void:
	# Godot Control._draw doesn't expose a rounded-rect primitive, so we
	# approximate with a centre rect + four side rects + four corner arcs.
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.5:
		draw_rect(rect, color, true)
		return
	var inner: Rect2 = Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(2 * r, 0))
	draw_rect(inner, color, true)
	var side: Rect2 = Rect2(rect.position + Vector2(0, r), Vector2(r, rect.size.y - 2 * r))
	draw_rect(side, color, true)
	side = Rect2(rect.position + Vector2(rect.size.x - r, r), Vector2(r, rect.size.y - 2 * r))
	draw_rect(side, color, true)
	_draw_corner(rect.position + Vector2(r, r), r, color, PI, 1.5 * PI)
	_draw_corner(rect.position + Vector2(rect.size.x - r, r), r, color, 1.5 * PI, TAU)
	_draw_corner(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color, 0.0, 0.5 * PI)
	_draw_corner(rect.position + Vector2(r, rect.size.y - r), r, color, 0.5 * PI, PI)


func _draw_rounded_outline(rect: Rect2, color: Color, radius: float, thickness: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.5:
		draw_rect(rect, color, false, thickness)
		return
	var pts: PackedVector2Array = PackedVector2Array()
	_append_arc(pts, rect.position + Vector2(r, r), r, PI, 1.5 * PI)
	_append_arc(pts, rect.position + Vector2(rect.size.x - r, r), r, 1.5 * PI, TAU)
	_append_arc(pts, rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0.0, 0.5 * PI)
	_append_arc(pts, rect.position + Vector2(r, rect.size.y - r), r, 0.5 * PI, PI)
	pts.append(pts[0])
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], color, thickness)


func _draw_corner(centre: Vector2, radius: float, color: Color, from_angle: float, to_angle: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(centre)
	_append_arc(pts, centre, radius, from_angle, to_angle)
	if pts.size() < 3:
		return
	var cols: PackedColorArray = PackedColorArray()
	for i in pts.size():
		cols.append(color)
	draw_polygon(pts, cols)


func _append_arc(pts: PackedVector2Array, centre: Vector2, radius: float, from_angle: float, to_angle: float) -> void:
	var steps: int = 6
	for i in steps + 1:
		var t: float = float(i) / float(steps)
		var a: float = lerp(from_angle, to_angle, t)
		pts.append(centre + Vector2(cos(a), sin(a)) * radius)


func _draw_room_icon(rect: Rect2, type: int) -> void:
	if _icon_font == null:
		return
	var glyph: String = _glyph_for(type)
	if glyph == "":
		return
	var size: Vector2 = _icon_font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_font_size)
	var centre: Vector2 = rect.position + rect.size * 0.5
	var origin: Vector2 = centre - size * 0.5 + Vector2(0, icon_font_size * 0.35)
	draw_string(_icon_font, origin, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_font_size, border_color)


# -------------------------------------------------------------------------
# Color / icon mapping
# -------------------------------------------------------------------------

func _fill_for(type: int, visited: bool, is_current: bool) -> Color:
	if is_current:
		return current_color
	if not visited and type != DungeonCell.Type.START:
		return unvisited_color
	match type:
		DungeonCell.Type.BOSS:    return boss_color
		DungeonCell.Type.SHOP:    return shop_color
		DungeonCell.Type.SHRINE:  return shrine_color
		DungeonCell.Type.ELITE:   return elite_color
		DungeonCell.Type.SECRET:  return secret_color
		DungeonCell.Type.START:   return visited_color.lightened(0.1)
	return visited_color


func _glyph_for(type: int) -> String:
	match type:
		DungeonCell.Type.BOSS:   return "B"
		DungeonCell.Type.SHOP:   return "$"
		DungeonCell.Type.SHRINE: return "*"
		DungeonCell.Type.ELITE:  return "!"
		DungeonCell.Type.SECRET: return "?"
		DungeonCell.Type.START:  return "S"
	return ""


# -------------------------------------------------------------------------
# Coordinate helpers
# -------------------------------------------------------------------------

func _cell_to_pixel(coord: Vector2i) -> Vector2:
	return Vector2(coord.x, coord.y) * (cell_size + cell_gap)


func _cell_centre(coord: Vector2i) -> Vector2:
	return _cell_to_pixel(coord) + cell_size * 0.5
