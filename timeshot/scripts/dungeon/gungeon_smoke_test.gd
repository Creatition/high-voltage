extends SceneTree
## Day 5 — Headless smoke test for the Gungeon-style dungeon pipeline.
##
## Run with:
##   godot --headless --script res://scripts/dungeon/gungeon_smoke_test.gd
##
## What it checks for every era × a handful of deterministic seeds:
##   - Builder produces between target_min and target_max rooms
##   - No two placed rooms overlap on the grid
##   - Every cell is in-bounds
##   - The dungeon graph is fully connected from START
##   - Decoded room template ids round-trip (encode/decode invariants)
##   - The minimap groupings reconstruct one entry per placed room
##
## Exit code 0 on success, 1 on any failure — wire into CI when ready.

const ERAS: Array = [
	"prehistoric", "aztec", "medieval", "present",
	"cyberpunk", "alien",
]
const SEEDS: Array = [1, 7, 42, 123, 9001, 31337]


func _init() -> void:
	var failures: int = 0
	var total: int = 0
	for era in ERAS:
		for s in SEEDS:
			total += 1
			var err: String = _run_one(era, s)
			if err != "":
				failures += 1
				printerr("[FAIL] era=%s seed=%d -> %s" % [era, int(s), err])
	if failures == 0:
		print("[OK] gungeon smoke test passed (%d configs)" % total)
		quit(0)
	else:
		printerr("[FAIL] %d/%d configs failed" % [failures, total])
		quit(1)


func _run_one(era: String, seed_value: int) -> String:
	var layout: DungeonLayout = DungeonLayout.new(era, seed_value)
	layout.grid_size = Vector2i(11, 11)

	var builder: GungeonLayoutBuilder = GungeonLayoutBuilder.new()
	var data: Dictionary = builder.build(layout)

	var carver: GungeonCorridorCarver = GungeonCorridorCarver.new()
	carver.carve(layout, data)

	# --- Invariant 1: room count in expected range ---
	var n_rooms: int = (data["rooms"] as Array).size()
	if n_rooms < builder.target_rooms_min - 1:
		return "room count too low (%d < %d)" % [n_rooms, builder.target_rooms_min - 1]
	if n_rooms > builder.target_rooms_max + 2:
		return "room count too high (%d > %d)" % [n_rooms, builder.target_rooms_max + 2]

	# --- Invariant 2: no overlap, every cell in-bounds ---
	var seen: Dictionary = {}
	for room in data["rooms"]:
		for c in room["cells_ws"]:
			var co: Vector2i = c
			if co.x < 0 or co.y < 0 or co.x >= layout.grid_size.x or co.y >= layout.grid_size.y:
				return "cell %s out of bounds" % str(co)
			if seen.has(co):
				return "cell %s used by two rooms" % str(co)
			seen[co] = true

	# --- Invariant 3: connectivity from start ---
	var reached: Dictionary = _flood(layout, layout.start_coord)
	for room in data["rooms"]:
		var any_in: bool = false
		for c in room["cells_ws"]:
			if reached.has(c):
				any_in = true
				break
		if not any_in:
			return "room %d unreachable from start" % int(room["id"])

	# --- Invariant 4: template-id encode/decode round-trip ---
	for c in layout.cells.values():
		if c.type == DungeonCell.Type.CORRIDOR:
			continue
		var meta: Dictionary = GungeonLayoutBuilder.decode_room_template_id(c.template_id)
		if meta.is_empty():
			return "cell %s has unrecognised template_id %s" % [str(c.coord), c.template_id]
		var rid: int = meta["room_id"]
		if not data["rooms_by_id"].has(rid):
			return "decoded room_id %d not in rooms_by_id" % rid

	# --- Invariant 5: groupings reconstruct one entry per placed room ---
	var group_ids: Dictionary = {}
	for c in layout.cells.values():
		if c.type == DungeonCell.Type.CORRIDOR:
			continue
		var meta: Dictionary = GungeonLayoutBuilder.decode_room_template_id(c.template_id)
		group_ids[int(meta["room_id"])] = true
	if group_ids.size() != n_rooms:
		return "minimap groups (%d) != placed rooms (%d)" % [group_ids.size(), n_rooms]

	return ""


func _flood(layout: DungeonLayout, start: Vector2i) -> Dictionary:
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
