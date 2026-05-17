extends RefCounted
class_name GungeonCorridorCarver
## Day 3 of the Gungeon-style dungeon pass.
##
## The Day 2 builder leaves some inter-room doors marked `corridor=true` — those
## are pairs of rooms that should be linked by a short stub corridor instead of
## a shared wall. This carver consumes those pending links, drops CORRIDOR cells
## into the empty space between the two rooms, and wires the connectivity so
## the player (and the minimap) can travel through.
##
## In the EtG reference image, most rooms share a wall but a noticeable
## minority hang off the side of a hallway. That's what this pass produces.
##
## The carver also runs an "orphan check": any room that ended up unreachable
## from START (due to placement order quirks) gets a forced corridor to its
## nearest reachable neighbour. This is the Day-3 analog of _ensure_connected
## in the legacy generator and prevents the smoke test from failing on
## sporadic disconnection.

const CORRIDOR_TEMPLATE_ID: String = "gcorr"
const MAX_FORCE_PATH_LEN: int = 12     ## Safety cap on emergency corridors


func carve(layout: DungeonLayout, data: Dictionary) -> void:
	## Resolve every pending corridor and ensure full connectivity from START.
	if layout == null:
		push_error("GungeonCorridorCarver.carve: null layout")
		return
	if data == null or data.is_empty():
		return
	_resolve_pending(layout, data)
	_repair_orphans(layout, data)


# -------------------------------------------------------------------------
# Pending stub corridors
# -------------------------------------------------------------------------

func _resolve_pending(layout: DungeonLayout, data: Dictionary) -> void:
	## Each pending door has from_cell / to_cell separated by a 1-cell gap.
	## We carve a single CORRIDOR cell into that gap and connect both rooms
	## to it. If the gap turned out to be larger (rare — happens when the
	## room placement was looser than expected) we fall back to an L-bend.
	var resolved: Array = []
	for door in data["pending"]:
		var from_cell: Vector2i = door["from_cell"]
		var to_cell: Vector2i = door["to_cell"]
		var dir: Vector2i = door["dir"]
		var gap: int = _orthogonal_distance(from_cell, to_cell)
		if gap == 0:
			# Defensive — Day 2 shouldn't queue zero-gap doors but if it does,
			# just connect directly and move on.
			layout.connect_cells(from_cell, to_cell)
			resolved.append(door)
			continue
		if gap == 2 and _are_collinear(from_cell, to_cell, dir):
			var mid: Vector2i = from_cell + dir
			_place_corridor_cell(layout, mid, data)
			layout.connect_cells(from_cell, mid)
			layout.connect_cells(mid, to_cell)
			resolved.append(door)
			continue
		# Wider gap (or off-axis): carve an L-bend through CORRIDOR cells.
		_carve_l_bend(layout, from_cell, to_cell, data)
		resolved.append(door)
	# Move resolved entries out of "pending" into "doors_corridor" for the
	# minimap to draw labels on.
	data["doors_corridor"] = resolved
	data["pending"] = []


# -------------------------------------------------------------------------
# Orphan repair
# -------------------------------------------------------------------------

func _repair_orphans(layout: DungeonLayout, data: Dictionary) -> void:
	var start: Vector2i = layout.start_coord
	var reached: Dictionary = _flood_fill(layout, start)
	for room in data["rooms"]:
		var any_reached: bool = false
		for c in room["cells_ws"]:
			if reached.has(c):
				any_reached = true
				break
		if any_reached:
			continue
		# Pick this room's cell that's closest to any reached cell and carve
		# a corridor to it.
		var target_in_room: Vector2i = room["cells_ws"][0]
		var nearest_reached: Vector2i = _nearest_in_set(reached.keys(), target_in_room)
		if nearest_reached == Vector2i(-9999, -9999):
			continue
		_carve_l_bend(layout, nearest_reached, target_in_room, data)
		# Refresh reach map for subsequent orphans.
		reached = _flood_fill(layout, start)


# -------------------------------------------------------------------------
# Corridor cell helpers
# -------------------------------------------------------------------------

func _place_corridor_cell(layout: DungeonLayout, coord: Vector2i, data: Dictionary) -> void:
	## Add a CORRIDOR cell at coord if not already present, and track it in
	## the side data so the minimap can render it.
	if data["occupied"].has(coord):
		# An existing room cell or corridor already covers this — don't
		## clobber it.
		return
	if coord.x < 0 or coord.y < 0 or coord.x >= layout.grid_size.x or coord.y >= layout.grid_size.y:
		return
	var c: DungeonCell = layout.add_cell(coord, DungeonCell.Type.CORRIDOR)
	c.template_id = CORRIDOR_TEMPLATE_ID
	if not data.has("corridor_cells"):
		data["corridor_cells"] = []
	data["corridor_cells"].append(coord)


func _carve_l_bend(layout: DungeonLayout, a: Vector2i, b: Vector2i, data: Dictionary) -> void:
	## Drop corridor cells along an L-shaped path from `a` to `b`, skipping
	## any cells that are already part of a room (so we glue against walls
	## naturally). Caps the total length so a runaway shouldn't carve forever.
	var elbow: Vector2i = Vector2i(b.x, a.y) if (layout.rng.randf() < 0.5) else Vector2i(a.x, b.y)
	_carve_line(layout, a, elbow, data)
	_carve_line(layout, elbow, b, data)


func _carve_line(layout: DungeonLayout, a: Vector2i, b: Vector2i, data: Dictionary) -> void:
	var here: Vector2i = a
	var steps: int = 0
	while here != b and steps < MAX_FORCE_PATH_LEN:
		steps += 1
		var step: Vector2i
		if here.x != b.x:
			step = Vector2i(signi(b.x - here.x), 0)
		else:
			step = Vector2i(0, signi(b.y - here.y))
		var next_coord: Vector2i = here + step
		var occupied_by: int = data["occupied"].get(next_coord, -1)
		if occupied_by == -1 and not layout.cells.has(next_coord):
			_place_corridor_cell(layout, next_coord, data)
		# connect_cells silently no-ops if either endpoint is missing, which
		# is the behaviour we want when running off the grid edge.
		layout.connect_cells(here, next_coord)
		here = next_coord


# -------------------------------------------------------------------------
# Geometry / search helpers
# -------------------------------------------------------------------------

func _flood_fill(layout: DungeonLayout, start: Vector2i) -> Dictionary:
	var reached: Dictionary = {}
	var stack: Array = [start]
	while not stack.is_empty():
		var here: Vector2i = stack.pop_back()
		if reached.has(here):
			continue
		var cell: DungeonCell = layout.cells.get(here, null)
		if cell == null:
			continue
		reached[here] = true
		for d in cell.connections:
			var nb: Vector2i = here + d
			if not reached.has(nb):
				stack.push_back(nb)
	return reached


func _nearest_in_set(coords: Array, target: Vector2i) -> Vector2i:
	var best: Vector2i = Vector2i(-9999, -9999)
	var best_d: int = 1 << 30
	for c in coords:
		var d: int = absi(c.x - target.x) + absi(c.y - target.y)
		if d < best_d:
			best_d = d
			best = c
	return best


func _orthogonal_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _are_collinear(a: Vector2i, b: Vector2i, dir: Vector2i) -> bool:
	if dir.x != 0 and a.y == b.y:
		return true
	if dir.y != 0 and a.x == b.x:
		return true
	return false
