extends RefCounted
class_name RoomShape
## Day 1 of the Gungeon-style dungeon pass.
##
## A RoomShape describes a multi-cell room footprint plus the cells along its
## perimeter where doors can attach. Enter-the-Gungeon rooms come in a handful
## of sizes (1x1, 1x2, 2x1, 2x2, 2x3, 3x2, L-shaped) and the dungeon visual
## variety in the reference image comes from mixing these freely.
##
## Cells are stored as Vector2i offsets from the room's origin. Door anchors
## are pairs of (cell offset, direction) meaning "this perimeter cell can
## open a door in direction d to whatever is placed in the next cell along d".
##
## A RoomShape is pure data — no node references. Day 2 (the layout builder)
## consumes it to place rooms; Day 4 (the minimap) consumes it to render the
## room outline. Nothing here knows about gameplay.

# --- Door anchor record ---
# A Dictionary with keys {cell: Vector2i, dir: Vector2i}. Using a dict instead
# of a custom class keeps it cheap to copy and easy to serialise for save data.

# Stable shape identifiers — Day 2 references these by name when picking a
# shape for a special room (e.g. BOSS prefers a 2x2 or 2x3).
const ID_1x1: String = "1x1"
const ID_1x2_H: String = "1x2_h"
const ID_1x2_V: String = "1x2_v"
const ID_2x2: String = "2x2"
const ID_2x3_H: String = "2x3_h"
const ID_2x3_V: String = "2x3_v"
const ID_L_NE: String = "L_ne"
const ID_L_NW: String = "L_nw"

var id: String = ID_1x1
var cells: Array[Vector2i] = [Vector2i.ZERO]
var door_anchors: Array = []           # Array[Dictionary{cell, dir}]


func _init(p_id: String = ID_1x1, p_cells: Array[Vector2i] = [], p_anchors: Array = []) -> void:
	id = p_id
	if p_cells.is_empty():
		cells = [Vector2i.ZERO]
	else:
		cells = p_cells.duplicate()
	door_anchors = p_anchors.duplicate(true)


# -------------------------------------------------------------------------
# Factory shapes — these are the eight stock shapes used by Day 2.
# -------------------------------------------------------------------------

static func small_1x1() -> RoomShape:
	## The default room. Four door anchors, one per cardinal direction.
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	var anchors: Array = [
		{"cell": Vector2i.ZERO, "dir": Vector2i(0, -1)},
		{"cell": Vector2i.ZERO, "dir": Vector2i(1, 0)},
		{"cell": Vector2i.ZERO, "dir": Vector2i(0, 1)},
		{"cell": Vector2i.ZERO, "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_1x1, cells, anchors)


static func wide_1x2_h() -> RoomShape:
	## A 2-wide horizontal room. Two cells side by side; door anchors on all
	## three non-internal sides per cell.
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_1x2_H, cells, anchors)


static func tall_1x2_v() -> RoomShape:
	## A 2-tall vertical room.
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_1x2_V, cells, anchors)


static func square_2x2() -> RoomShape:
	## A 2x2 chamber — the classic mid-size combat arena and the typical
	## EtG shop/boss footprint when the boss isn't bespoke.
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
	]
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_2x2, cells, anchors)


static func wide_2x3_h() -> RoomShape:
	## A 3-wide, 2-tall hall — used for boss arenas and treasure halls.
	var cells: Array[Vector2i] = []
	for x in range(3):
		for y in range(2):
			cells.append(Vector2i(x, y))
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(2, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(2, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(2, 1), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(2, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_2x3_H, cells, anchors)


static func tall_2x3_v() -> RoomShape:
	## A 2-wide, 3-tall hall — the vertical sibling of wide_2x3_h.
	var cells: Array[Vector2i] = []
	for x in range(2):
		for y in range(3):
			cells.append(Vector2i(x, y))
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(1, 2), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 2), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(1, 2), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 2), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_2x3_V, cells, anchors)


static func l_shape_ne() -> RoomShape:
	## L-shape opening toward the north-east. Three cells in an L. Adds shape
	## variety so the dungeon doesn't look like a grid of bricks.
	##  X X
	##  X .
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1),
	]
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 1), "dir": Vector2i(-1, 0)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_L_NE, cells, anchors)


static func l_shape_nw() -> RoomShape:
	## L-shape opening toward the north-west — the mirror of l_shape_ne.
	##  X X
	##  . X
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(1, 1),
	]
	var anchors: Array = [
		{"cell": Vector2i(0, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(0, -1)},
		{"cell": Vector2i(1, 0), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(1, 0)},
		{"cell": Vector2i(1, 1), "dir": Vector2i(0, 1)},
		{"cell": Vector2i(0, 0), "dir": Vector2i(-1, 0)},
	]
	return RoomShape.new(ID_L_NW, cells, anchors)


# -------------------------------------------------------------------------
# Catalogues — pickers used by Day 2.
# -------------------------------------------------------------------------

static func all_shapes() -> Array:
	return [
		small_1x1(), wide_1x2_h(), tall_1x2_v(), square_2x2(),
		wide_2x3_h(), tall_2x3_v(), l_shape_ne(), l_shape_nw(),
	]


static func normal_pool() -> Array:
	## Weighted pool for NORMAL combat rooms. Repeats bias the picker.
	## 1x1 dominates so the dungeon still has a clear backbone; larger
	## shapes appear less often, for impact.
	return [
		small_1x1(), small_1x1(), small_1x1(), small_1x1(),
		wide_1x2_h(), tall_1x2_v(),
		square_2x2(),
		l_shape_ne(), l_shape_nw(),
	]


static func boss_shape() -> RoomShape:
	## Bosses get the big hall by default. Bespoke arenas are still chosen
	## by BossArenas at template-stamp time; this is just the footprint.
	return wide_2x3_h()


static func shop_shape() -> RoomShape:
	## EtG shops are typically 2x2 with the keeper in the centre.
	return square_2x2()


static func treasure_shape() -> RoomShape:
	## Treasure/shrine rooms — slightly wider than 1x1 so the chest reads.
	return wide_1x2_h()


# -------------------------------------------------------------------------
# Geometry helpers — Day 2/4 consume these.
# -------------------------------------------------------------------------

func cells_at(origin: Vector2i) -> Array[Vector2i]:
	## World-space cells this shape would occupy if its origin were placed
	## at `origin`.
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(origin + c)
	return out


func door_anchors_at(origin: Vector2i) -> Array:
	## World-space door anchor records. Each entry is
	## {cell: Vector2i, dir: Vector2i, target: Vector2i}
	## where `target` is the cell on the other side of the anchor.
	var out: Array = []
	for a in door_anchors:
		var cell_ws: Vector2i = origin + (a["cell"] as Vector2i)
		var dir: Vector2i = a["dir"]
		out.append({"cell": cell_ws, "dir": dir, "target": cell_ws + dir})
	return out


func bounds_at(origin: Vector2i) -> Rect2i:
	## Axis-aligned bounding box (inclusive of all cells) in world space.
	if cells.is_empty():
		return Rect2i(origin, Vector2i.ONE)
	var min_v: Vector2i = cells[0]
	var max_v: Vector2i = cells[0]
	for c in cells:
		min_v.x = mini(min_v.x, c.x)
		min_v.y = mini(min_v.y, c.y)
		max_v.x = maxi(max_v.x, c.x)
		max_v.y = maxi(max_v.y, c.y)
	return Rect2i(origin + min_v, max_v - min_v + Vector2i.ONE)


func occupies(origin: Vector2i, coord: Vector2i) -> bool:
	for c in cells:
		if origin + c == coord:
			return true
	return false


func cell_count() -> int:
	return cells.size()
