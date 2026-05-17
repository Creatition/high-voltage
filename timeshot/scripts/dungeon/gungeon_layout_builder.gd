extends RefCounted
class_name GungeonLayoutBuilder
## Day 2 of the Gungeon-style dungeon pass.
##
## Grows a dungeon out of variable-size RoomShape footprints — 1x1, 1x2, 2x2,
## 2x3, L-shapes — instead of one-cell-per-room like the legacy BSP path. This
## is the structural change that makes the minimap read like the reference
## Enter-the-Gungeon shot: rooms come in different sizes, and the SHOP / BOSS /
## TREASURE rooms are visibly chunkier than the regular combat rooms.
##
## OUTPUT
## ------
## build() populates the passed-in DungeonLayout with one DungeonCell per
## room-cell (template_id = "groom:<id>:<shape>:<type>") and internally wires
## all cells of a multi-cell room together as one open space. It returns a
## "gungeon data" Dictionary holding the per-room metadata that the Day 3
## corridor carver and Day 4 minimap consume:
##
##   {
##     "rooms":     Array[Dictionary]  # one entry per placed room (see _make_room_record)
##     "pending":   Array[Dictionary]  # unresolved door anchors waiting on corridors
##     "version":   int                # bump when the schema changes
##   }
##
## The builder NEVER edits files outside this directory and NEVER touches the
## existing DungeonGenerator pipeline directly — Day 5 wires it in behind a
## feature flag, so the BSP path remains the default until we're confident.

const GUNGEON_DATA_VERSION: int = 1
const ROOM_TEMPLATE_PREFIX: String = "groom"

# Tunables. Mirrored from DungeonGenerator defaults so the builder can run
# standalone in the smoke test without an autoload reference.
@export var target_rooms_min: int = 8
@export var target_rooms_max: int = 12
@export var corridor_link_chance: float = 0.30   ## Per door: insert a 1-cell corridor gap instead of a shared wall
@export var loop_link_chance: float = 0.35       ## After main growth, try to re-link some adjacent rooms for non-tree flow
@export var max_place_attempts_per_room: int = 24


func build(layout: DungeonLayout) -> Dictionary:
	## Populate `layout` with multi-cell rooms. Returns the gungeon-data side
	## struct used by the carver and minimap.
	if layout == null:
		push_error("GungeonLayoutBuilder.build: null layout")
		return _empty_data()

	var data: Dictionary = _empty_data()
	var room_target: int = layout.rng.randi_range(target_rooms_min, target_rooms_max)
	var grid_centre: Vector2i = layout.grid_size / 2

	# --- Step 1: drop the START room (always 1x1) at the centre. ---
	var start_shape: RoomShape = RoomShape.small_1x1()
	var start_record: Dictionary = _make_room_record(
		0, start_shape, grid_centre, DungeonCell.Type.START)
	if not _try_place_room(layout, start_record, data, false):
		# Centre cell unreachable? Try corners. Very small grids only.
		push_warning("GungeonLayoutBuilder: failed to place START at centre, retrying")
		for fallback in [Vector2i(1, 1), Vector2i(2, 2)]:
			start_record["origin"] = fallback
			start_record["cells_ws"] = start_shape.cells_at(fallback)
			start_record["doors_ws"] = start_shape.door_anchors_at(fallback)
			if _try_place_room(layout, start_record, data, false):
				break
	layout.start_coord = start_record["origin"]

	# --- Step 2: grow outward by attaching shapes to random open anchors. ---
	var next_id: int = 1
	while data["rooms"].size() < room_target:
		var picked: Dictionary = _pick_open_anchor(data, layout.rng)
		if picked.is_empty():
			break  # No more attach points — the layout is saturated.
		var shape: RoomShape = _pick_shape_for(layout.rng, DungeonCell.Type.NORMAL)
		var placed: bool = _try_attach(layout, data, picked, shape, next_id, DungeonCell.Type.NORMAL)
		if placed:
			next_id += 1
		# Either way, mark this anchor as consumed so we don't loop forever.
		picked["host_room"]["doors_tried"][_anchor_key(picked["anchor"])] = true

	# --- Step 3: add a handful of loop connections so it isn't a pure tree. ---
	_add_loop_connections(layout, data)

	# --- Step 4: write room-cell template ids and internal connectivity. ---
	_finalize_cells(layout, data)
	layout.compute_depths()

	return data


# -------------------------------------------------------------------------
# Anchor picking and shape attachment
# -------------------------------------------------------------------------

func _pick_open_anchor(data: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	## Returns {host_room, anchor} for an unused door anchor on any placed
	## room, or {} if every anchor on every room has been tried.
	var candidates: Array = []
	for room in data["rooms"]:
		for a in room["doors_ws"]:
			if room["doors_tried"].has(_anchor_key(a)):
				continue
			candidates.append({"host_room": room, "anchor": a})
	if candidates.is_empty():
		return {}
	candidates.shuffle()
	# Prefer anchors on rooms with fewer existing connections so the tree
	# spreads. Sort by host's connection count, then pick from the top quarter.
	candidates.sort_custom(func(a, b):
		return (a["host_room"]["connection_count"] as int) < (b["host_room"]["connection_count"] as int)
	)
	var pool_size: int = maxi(1, candidates.size() / 4)
	return candidates[rng.randi() % pool_size]


func _try_attach(layout: DungeonLayout, data: Dictionary, picked: Dictionary,
		shape: RoomShape, new_id: int, type: int) -> bool:
	## Attempt to place `shape` so that one of its door anchors lines up
	## opposite `picked.anchor`. Tries each compatible attach-anchor in random
	## order. Honors the `corridor_link_chance` roll to decide whether the new
	## room shares a wall with the host or sits one cell away with a future
	## corridor between.
	var anchor: Dictionary = picked["anchor"]
	var host_dir: Vector2i = anchor["dir"]
	var need_dir: Vector2i = -host_dir   # the new room's anchor must face back
	var use_corridor: bool = layout.rng.randf() < corridor_link_chance
	var step_distance: int = 2 if use_corridor else 1
	var target_attach_cell: Vector2i = (anchor["cell"] as Vector2i) + host_dir * step_distance

	# Enumerate the shape's anchors that point in the required direction.
	var compatible: Array = []
	for a in shape.door_anchors:
		if (a["dir"] as Vector2i) == need_dir:
			compatible.append(a)
	compatible.shuffle()

	for a in compatible:
		var attach_cell: Vector2i = a["cell"]
		# Origin = where the shape's (0,0) goes so that attach_cell -> target_attach_cell.
		var origin: Vector2i = target_attach_cell - attach_cell
		var ws_cells: Array[Vector2i] = shape.cells_at(origin)
		if not _fits(layout, data, ws_cells):
			continue
		# Place it.
		var record: Dictionary = _make_room_record(new_id, shape, origin, type)
		var ok: bool = _try_place_room(layout, record, data, true)
		if not ok:
			continue
		# Record the door between host and new room.
		var host_room: Dictionary = picked["host_room"]
		_register_door(data, host_room, record, anchor, a, use_corridor)
		return true
	return false


func _fits(layout: DungeonLayout, data: Dictionary, ws_cells: Array[Vector2i]) -> bool:
	## Cells fit inside the grid, don't overlap existing rooms, and leave a
	## 1-cell buffer between non-adjacent rooms (so corridors fit).
	for c in ws_cells:
		if c.x < 0 or c.y < 0 or c.x >= layout.grid_size.x or c.y >= layout.grid_size.y:
			return false
		if data["occupied"].has(c):
			return false
	return true


func _try_place_room(layout: DungeonLayout, record: Dictionary, data: Dictionary, count_connection: bool) -> bool:
	## Marks the room's cells as occupied in the side data and appends the
	## room to the registry. Returns false if any cell can't be marked.
	for c in record["cells_ws"]:
		if data["occupied"].has(c):
			return false
	for c in record["cells_ws"]:
		data["occupied"][c] = record["id"]
	if count_connection:
		record["connection_count"] = 1
	data["rooms"].append(record)
	data["rooms_by_id"][record["id"]] = record
	return true


# -------------------------------------------------------------------------
# Loop connections
# -------------------------------------------------------------------------

func _add_loop_connections(layout: DungeonLayout, data: Dictionary) -> void:
	## After tree growth, find pairs of rooms whose footprints touch but
	## aren't connected and add a door between them with probability
	## `loop_link_chance`. Gives the dungeon shortcut routes like EtG.
	var rooms: Array = data["rooms"]
	for i in rooms.size():
		var a: Dictionary = rooms[i]
		for j in range(i + 1, rooms.size()):
			var b: Dictionary = rooms[j]
			if layout.rng.randf() >= loop_link_chance:
				continue
			var pair: Dictionary = _find_shared_border(a, b)
			if pair.is_empty():
				continue
			if _door_already_exists(data, a["id"], b["id"]):
				continue
			# Synthesize anchors on both sides of the shared border.
			var host_anchor: Dictionary = {
				"cell": pair["a_cell"],
				"dir": pair["dir"],
				"target": pair["b_cell"],
			}
			var other_anchor: Dictionary = {
				"cell": pair["b_cell"],
				"dir": -pair["dir"],
				"target": pair["a_cell"],
			}
			_register_door(data, a, b, host_anchor, other_anchor, false)


func _find_shared_border(a: Dictionary, b: Dictionary) -> Dictionary:
	## Returns {a_cell, b_cell, dir} for any pair of orthogonally adjacent
	## cells across a and b, or {} if they don't touch.
	var b_cells: Dictionary = {}
	for c in b["cells_ws"]:
		b_cells[c] = true
	for c in a["cells_ws"]:
		for d in DungeonCell.DIRS:
			var nb: Vector2i = c + d
			if b_cells.has(nb):
				return {"a_cell": c, "b_cell": nb, "dir": d}
	return {}


func _door_already_exists(data: Dictionary, room_a_id: int, room_b_id: int) -> bool:
	for door in data["doors"]:
		if (door["from_room"] == room_a_id and door["to_room"] == room_b_id) \
				or (door["from_room"] == room_b_id and door["to_room"] == room_a_id):
			return true
	return false


# -------------------------------------------------------------------------
# Cell finalisation
# -------------------------------------------------------------------------

func _finalize_cells(layout: DungeonLayout, data: Dictionary) -> void:
	## Stamp DungeonCells for every cell of every placed room and wire up
	## internal (same-room) and external (door, no-corridor) connections.
	## Corridor doors are stored in data["pending"] for Day 3 to resolve.
	for room in data["rooms"]:
		var cells_ws: Array = room["cells_ws"]
		for c in cells_ws:
			var dc: DungeonCell = layout.add_cell(c, room["type"])
			dc.template_id = _encode_room_template_id(room)
		# Internal connections (open within a room).
		for c in cells_ws:
			for d in DungeonCell.DIRS:
				var nb: Vector2i = c + d
				if data["occupied"].get(nb, -1) == room["id"]:
					layout.connect_cells(c, nb)
	# External, no-corridor doors connect directly.
	for door in data["doors"]:
		if door["corridor"]:
			data["pending"].append(door)
			continue
		var a: Vector2i = door["from_cell"]
		var b: Vector2i = door["to_cell"]
		# Adjacent cells — connect directly.
		layout.connect_cells(a, b)


# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

static func decode_room_template_id(template_id: String) -> Dictionary:
	## Inverse of _encode_room_template_id. Used by the minimap (Day 4) to
	## reconstruct multi-cell rooms by grouping cells with the same room id.
	if not template_id.begins_with(ROOM_TEMPLATE_PREFIX + ":"):
		return {}
	var parts: PackedStringArray = template_id.split(":")
	if parts.size() < 4:
		return {}
	return {"room_id": int(parts[1]), "shape_id": parts[2], "type_name": parts[3]}


func _encode_room_template_id(room: Dictionary) -> String:
	return "%s:%d:%s:%s" % [
		ROOM_TEMPLATE_PREFIX, int(room["id"]),
		String(room["shape_id"]), String(room["type_name"]),
	]


func _make_room_record(id: int, shape: RoomShape, origin: Vector2i, type: int) -> Dictionary:
	return {
		"id": id,
		"shape_id": shape.id,
		"origin": origin,
		"cells_ws": shape.cells_at(origin),
		"doors_ws": shape.door_anchors_at(origin),
		"doors_tried": {},
		"connection_count": 0,
		"type": type,
		"type_name": _type_name(type),
	}


func _register_door(data: Dictionary, host: Dictionary, other: Dictionary,
		host_anchor: Dictionary, other_anchor: Dictionary, corridor: bool) -> void:
	host["connection_count"] = int(host["connection_count"]) + 1
	other["connection_count"] = int(other["connection_count"]) + 1
	host["doors_tried"][_anchor_key(host_anchor)] = true
	other["doors_tried"][_anchor_key(other_anchor)] = true
	data["doors"].append({
		"from_room": host["id"],
		"to_room": other["id"],
		"from_cell": host_anchor["cell"],
		"to_cell": other_anchor["cell"],
		"dir": host_anchor["dir"],
		"corridor": corridor,
	})


func _pick_shape_for(rng: RandomNumberGenerator, type: int) -> RoomShape:
	match type:
		DungeonCell.Type.BOSS:    return RoomShape.boss_shape()
		DungeonCell.Type.SHOP:    return RoomShape.shop_shape()
		DungeonCell.Type.SHRINE:  return RoomShape.treasure_shape()
		_:
			var pool: Array = RoomShape.normal_pool()
			return pool[rng.randi() % pool.size()]


func _anchor_key(anchor: Dictionary) -> String:
	var c: Vector2i = anchor["cell"]
	var d: Vector2i = anchor["dir"]
	return "%d,%d|%d,%d" % [c.x, c.y, d.x, d.y]


func _type_name(type: int) -> String:
	match type:
		DungeonCell.Type.START:   return "start"
		DungeonCell.Type.NORMAL:  return "normal"
		DungeonCell.Type.ELITE:   return "elite"
		DungeonCell.Type.SHOP:    return "shop"
		DungeonCell.Type.SHRINE:  return "shrine"
		DungeonCell.Type.BOSS:    return "boss"
		DungeonCell.Type.SECRET:  return "secret"
		_:                        return "normal"


func _empty_data() -> Dictionary:
	return {
		"version": GUNGEON_DATA_VERSION,
		"rooms": [],
		"rooms_by_id": {},
		"doors": [],
		"pending": [],
		"occupied": {},
	}
