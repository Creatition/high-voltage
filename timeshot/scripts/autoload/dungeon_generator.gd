extends Node
## Autoload responsible for producing a DungeonLayout for an era.
##
## Pipeline:
##   1. Layout (Day 2) — BSP partition + chosen-cell-per-leaf + corridor carving.
##   2. Tag (Day 3)    — START / BOSS / SHOP / SHRINE / SECRET / ELITE / NORMAL.
##   3. Theme (Day 4)  — fill cell.era + theme metadata.
##   4. Stamp (Day 5)  — pick a template id per room based on type + era.
##   5. Populate (Day 6) — enemy / trap budget per room.
##   6. Loot (Day 9)   — pickup distribution + secret hint placement.
##
## The runner (DungeonRunner autoload, Day 7) reads the finished layout and
## stamps room scenes into the scene tree as the player walks through doors.

# --- Tunables (Day 10 balance pass) ---
# Defaults chosen so a single dungeon is ~6-8 minutes for an average player:
# - 8 rooms median × ~45s per combat room ≈ 6 minutes
# - +shop (15s) + shrine (10s) + boss (90s) ≈ 7.5 minutes
@export var rooms_per_era_min: int = 7
@export var rooms_per_era_max: int = 10
@export var grid_size: Vector2i = Vector2i(9, 9)
@export var bsp_max_depth: int = 3
@export var elite_room_chance: float = 0.18
@export var shop_room_chance: float = 0.85
@export var shrine_room_chance: float = 0.75
@export var secret_room_chance: float = 0.55
# Day 10 — fail-safe: if the generator can't place a boss after this many
# attempts (e.g. broken connectivity), it gives up and the runner falls back
# to the legacy linear queue rather than booting the player into a no-boss
# dungeon.
@export var max_regen_attempts: int = 4
# Day 5 (Gungeon pass) — flip on to use the multi-cell RoomShape pipeline
# (room_shape.gd + gungeon_layout_builder.gd + gungeon_corridor_carver.gd)
# instead of the legacy BSP placement. The new pipeline produces variable-
# size rooms and stub corridors to match the Enter-the-Gungeon reference.
@export var use_gungeon_layout: bool = true

# --- Active layout, owned by the generator while the era is being played ---
var current_layout: DungeonLayout = null
# Side data from the gungeon builder — read by GungeonMinimap. Empty when
# use_gungeon_layout is false or when generation fell back to BSP.
var current_gungeon_data: Dictionary = {}


func generate(era_id: String, seed_value: int = 0) -> DungeonLayout:
	## Build a brand-new layout for `era_id` and cache it as current_layout.
	## Day 10: retry up to max_regen_attempts times if the produced layout
	## fails its sanity check (no boss / unreachable rooms / too few rooms).
	var attempt := 0
	var layout: DungeonLayout = null
	while attempt < max_regen_attempts:
		attempt += 1
		var seed_for_attempt: int = seed_value if seed_value != 0 else 0
		layout = DungeonLayout.new(era_id, seed_for_attempt)
		layout.grid_size = grid_size
		current_gungeon_data = {}
		if use_gungeon_layout:
			_place_rooms_gungeon(layout)
		else:
			_place_rooms(layout)
		_tag_special_rooms(layout)
		_apply_theme(layout)
		_stamp_templates(layout)
		_populate_rooms(layout)
		_place_loot_and_secrets(layout)
		if _sanity_check(layout):
			break
	current_layout = layout
	return layout


func _sanity_check(layout: DungeonLayout) -> bool:
	if layout == null:
		return false
	if layout.find_rooms_of_type(DungeonCell.Type.START).is_empty():
		return false
	if layout.find_rooms_of_type(DungeonCell.Type.BOSS).is_empty():
		return false
	if layout.room_count() < rooms_per_era_min - 1:
		return false
	# Boss must be reachable from start.
	var reached: Dictionary = {}
	var stack: Array = [layout.start_coord]
	while not stack.is_empty():
		var here: Vector2i = stack.pop_back()
		if reached.has(here):
			continue
		reached[here] = true
		var cur: DungeonCell = layout.cells.get(here, null)
		if cur == null:
			continue
		for d in cur.connections:
			stack.push_back(here + d)
	return reached.has(layout.boss_coord)


# -------------------------------------------------------------------------
# Day 2 — layout
# -------------------------------------------------------------------------

func _place_rooms(layout: DungeonLayout) -> void:
	## Enter-the-Gungeon style layout: every cell is a fully-walled room, and
	## every connection is a *direct* door between two orthogonally adjacent
	## rooms. No long carved corridor chains — the room graph IS the dungeon.
	##
	## Algorithm:
	##  1. Drop the START room at the grid centre.
	##  2. Grow outward by repeatedly picking a frontier cell (empty, adjacent
	##     to a placed room) and connecting it to ONE existing neighbour. We
	##     bias the pick toward cells with fewer placed neighbours so the
	##     dungeon spreads out instead of clumping into a blob.
	##  3. Sprinkle 1-3 extra adjacencies for non-linear flow (EtG-style loops
	##     and shortcut doors).
	##  4. Compute depths so the rest of the pipeline can tag boss / shop / etc.
	var room_target: int = layout.rng.randi_range(rooms_per_era_min, rooms_per_era_max)
	var centre := layout.grid_size / 2
	layout.start_coord = centre
	layout.add_cell(centre, DungeonCell.Type.NORMAL)

	var rooms_placed: int = 1
	var safety: int = layout.grid_size.x * layout.grid_size.y + 4
	while rooms_placed < room_target and safety > 0:
		safety -= 1
		var frontier: Array[Vector2i] = _collect_frontier(layout)
		if frontier.is_empty():
			break
		# Sort by adjacent-room count ascending so we prefer "edge" frontier
		# cells; then pick randomly from the top handful so the layout still
		# feels organic.
		frontier.sort_custom(func(a, b):
			return _count_room_neighbours(layout, a) < _count_room_neighbours(layout, b)
		)
		var pool_size: int = mini(4, frontier.size())
		var chosen: Vector2i = frontier[layout.rng.randi() % pool_size]
		layout.add_cell(chosen, DungeonCell.Type.NORMAL)
		# Wire the new room to exactly one existing neighbour (tree growth).
		var dirs_with_room: Array[Vector2i] = []
		for d in DungeonCell.DIRS:
			var nb: DungeonCell = layout.cells.get(chosen + d, null)
			if nb != null and nb.is_room():
				dirs_with_room.append(d)
		dirs_with_room.shuffle()
		if not dirs_with_room.is_empty():
			layout.connect_cells(chosen, chosen + dirs_with_room[0])
		rooms_placed += 1

	_add_loop_connections(layout, layout.rng.randi_range(1, 3))
	layout.add_cell(centre, DungeonCell.Type.START)
	layout.compute_depths()


func _place_rooms_gungeon(layout: DungeonLayout) -> void:
	## Day 5 — Gungeon-style pipeline. Builds multi-cell rooms via RoomShape +
	## GungeonLayoutBuilder, then carves stub corridors with GungeonCorridorCarver.
	## Side data is stashed on current_gungeon_data so the minimap can render
	## multi-cell room groupings. The rest of the pipeline (tag / theme / stamp
	## / populate / loot) still sees a normal DungeonLayout and behaves the same.
	var builder := GungeonLayoutBuilder.new()
	builder.target_rooms_min = rooms_per_era_min
	builder.target_rooms_max = rooms_per_era_max
	var data: Dictionary = builder.build(layout)
	var carver := GungeonCorridorCarver.new()
	carver.carve(layout, data)
	current_gungeon_data = data
	# The builder seeds layout.start_coord; make sure the START cell exists.
	if not layout.cells.has(layout.start_coord):
		layout.add_cell(layout.start_coord, DungeonCell.Type.START)


func _collect_frontier(layout: DungeonLayout) -> Array[Vector2i]:
	## Empty in-bounds cells with at least one placed-room neighbour.
	var seen: Dictionary = {}
	var out: Array[Vector2i] = []
	for coord in layout.cells.keys():
		for d in DungeonCell.DIRS:
			var n: Vector2i = coord + d
			if seen.has(n):
				continue
			if layout.cells.has(n):
				continue
			if not _in_bounds(n, layout.grid_size):
				continue
			seen[n] = true
			out.append(n)
	return out


func _count_room_neighbours(layout: DungeonLayout, coord: Vector2i) -> int:
	var n: int = 0
	for d in DungeonCell.DIRS:
		var nb: DungeonCell = layout.cells.get(coord + d, null)
		if nb != null and nb.is_room():
			n += 1
	return n


func _add_loop_connections(layout: DungeonLayout, count: int) -> void:
	## Find room pairs that are orthogonally adjacent but currently not
	## connected, and join them. Keeps the dungeon from being a pure tree
	## so the player has shortcuts and alternate paths between rooms.
	var added: int = 0
	var coords: Array = layout.cells.keys()
	coords.shuffle()
	for coord in coords:
		if added >= count:
			return
		var cell: DungeonCell = layout.cells.get(coord, null)
		if cell == null or not cell.is_room():
			continue
		var dirs := DungeonCell.DIRS.duplicate()
		dirs.shuffle()
		for d in dirs:
			var nb: DungeonCell = layout.cells.get(coord + d, null)
			if nb == null or not nb.is_room():
				continue
			if cell.is_connected_to(d):
				continue
			layout.connect_cells(coord, nb.coord)
			added += 1
			break


func _dedupe(arr: Array[Vector2i]) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var out: Array[Vector2i] = []
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			out.append(v)
	return out


func _in_bounds(c: Vector2i, grid_size: Vector2i) -> bool:
	## Returns true if coord `c` is inside the [0, grid_size) grid box.
	return c.x >= 0 and c.y >= 0 and c.x < grid_size.x and c.y < grid_size.y


func _carve_corridor(layout: DungeonLayout, leaf_a: Rect2i, leaf_b: Rect2i, room_coords: Array[Vector2i]) -> void:
	var a: Vector2i = _closest_room_in_rect(room_coords, leaf_a, leaf_b.get_center())
	var b: Vector2i = _closest_room_in_rect(room_coords, leaf_b, leaf_a.get_center())
	if a == Vector2i(-1, -1) or b == Vector2i(-1, -1):
		return
	# L-bend with a random elbow orientation.
	var elbow := Vector2i(b.x, a.y) if layout.rng.randf() < 0.5 else Vector2i(a.x, b.y)
	_carve_line(layout, a, elbow)
	_carve_line(layout, elbow, b)


func _closest_room_in_rect(room_coords: Array[Vector2i], rect: Rect2i, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in room_coords:
		if not rect.has_point(c):
			continue
		var d: float = c.distance_squared_to(target)
		if d < best_d:
			best_d = d
			best = c
	return best


func _carve_line(layout: DungeonLayout, a: Vector2i, b: Vector2i) -> void:
	var here := a
	while here != b:
		var step := Vector2i(signi(b.x - here.x), 0) if here.x != b.x else Vector2i(0, signi(b.y - here.y))
		var next := here + step
		if not layout.cells.has(next):
			layout.add_cell(next, DungeonCell.Type.CORRIDOR)
		layout.connect_cells(here, next)
		here = next


func _ensure_connected(layout: DungeonLayout, room_coords: Array[Vector2i]) -> void:
	# BFS from start; whatever rooms aren't reached get a forced corridor.
	var reached: Dictionary = {}
	var stack: Array[Vector2i] = [layout.start_coord]
	while not stack.is_empty():
		var here: Vector2i = stack.pop_back()
		if reached.has(here):
			continue
		reached[here] = true
		var cur: DungeonCell = layout.cells.get(here, null)
		if cur == null:
			continue
		for d in cur.connections:
			var nbr: Vector2i = here + d
			if not reached.has(nbr):
				stack.push_back(nbr)
	for coord in room_coords:
		if not reached.has(coord):
			_carve_line(layout, layout.start_coord, coord)


# -------------------------------------------------------------------------
# Day 3 — special-room tagging
# -------------------------------------------------------------------------

func _tag_special_rooms(layout: DungeonLayout) -> void:
	## Tag a curated set of special rooms. Rules:
	##   - BOSS: the room with the highest depth from START. Always tagged.
	##   - SHOP: a leaf room (1 connection) at mid-depth, biased toward
	##           somewhere safe to spend money.
	##   - SHRINE: a leaf at later-than-mid depth (reward for going deep).
	##   - ELITE: ~20% of NORMAL rooms at depth >= 2.
	##   - SECRET: a "would-be" cell adjacent to two rooms — accessed by a
	##             breakable wall (Day 9 makes the wall functional).
	##
	## The order matters: place BOSS first so we don't accidentally overwrite
	## it with SHOP/SHRINE/ELITE.

	layout.compute_depths()
	var boss := _place_boss(layout)
	_place_shop_and_shrine(layout, boss)
	_place_elites(layout)
	_place_secret_room(layout)


func _place_boss(layout: DungeonLayout) -> DungeonCell:
	var furthest := layout.furthest_room()
	if furthest == null:
		return null
	# Don't allow the start room to also be the boss room (tiny dungeons).
	if furthest.coord == layout.start_coord:
		# Force at least one extra room.
		var dirs := DungeonCell.DIRS.duplicate()
		dirs.shuffle()
		for d in dirs:
			var c: Vector2i = layout.start_coord + d
			if _in_bounds(c, layout.grid_size) and not layout.cells.has(c):
				layout.add_cell(c, DungeonCell.Type.BOSS)
				layout.connect_cells(layout.start_coord, c)
				layout.boss_coord = c
				return layout.get_cell(c)
		return null
	furthest.type = DungeonCell.Type.BOSS
	layout.boss_coord = furthest.coord
	# EtG-style: boss room has exactly one entrance so the arena is sealed.
	_prune_to_single_connection(layout, furthest)
	return furthest


func _prune_to_single_connection(layout: DungeonLayout, room: DungeonCell) -> void:
	if room.connections.size() <= 1:
		return
	# Pick the entry that leads back toward the start (shortest depth neighbour),
	# drop the rest from both sides.
	var keep: Vector2i = room.connections[0]
	var best_depth: int = INF
	for d in room.connections:
		var nb: DungeonCell = layout.cells.get(room.coord + d, null)
		if nb == null:
			continue
		if nb.depth >= 0 and nb.depth < best_depth:
			best_depth = nb.depth
			keep = d
	var to_remove: Array[Vector2i] = []
	for d in room.connections:
		if d != keep:
			to_remove.append(d)
	for d in to_remove:
		var nb2: DungeonCell = layout.cells.get(room.coord + d, null)
		room.disconnect_from(d)
		if nb2 != null:
			nb2.disconnect_from(-d)


func _place_shop_and_shrine(layout: DungeonLayout, boss: DungeonCell) -> void:
	## A "leaf room" is a normal room with exactly one connection — a
	## branching cul-de-sac, the natural place for an isolated terminal /
	## shrine.
	var leaves: Array = []
	for c in layout.rooms():
		if c.type != DungeonCell.Type.NORMAL:
			continue
		if c.depth < 1:
			continue
		if c.connections.size() == 1:
			leaves.append(c)
	# Sort by depth so we can scoop a "near" and a "far" leaf.
	leaves.sort_custom(func(a, b): return a.depth < b.depth)

	if not leaves.is_empty() and layout.rng.randf() < shop_room_chance:
		var shop_cell: DungeonCell = leaves[0]
		shop_cell.type = DungeonCell.Type.SHOP
		leaves.erase(shop_cell)

	if not leaves.is_empty() and layout.rng.randf() < shrine_room_chance:
		var shrine_cell: DungeonCell = leaves[-1]
		shrine_cell.type = DungeonCell.Type.SHRINE


func _place_elites(layout: DungeonLayout) -> void:
	for c in layout.rooms():
		if c.type != DungeonCell.Type.NORMAL:
			continue
		if c.depth < 2:
			continue
		if layout.rng.randf() < elite_room_chance:
			c.type = DungeonCell.Type.ELITE


func _place_secret_room(layout: DungeonLayout) -> void:
	## Find an empty cell that touches at least two existing rooms. Mark it
	## SECRET; the SECRET cell connects only to one of those rooms (the
	## breakable-wall room).
	if layout.rng.randf() >= secret_room_chance:
		return
	var candidates: Array[Vector2i] = []
	for x in range(layout.grid_size.x):
		for y in range(layout.grid_size.y):
			var c := Vector2i(x, y)
			if layout.cells.has(c):
				continue
			var room_neighbours: int = 0
			for d in DungeonCell.DIRS:
				var n: DungeonCell = layout.cells.get(c + d, null)
				if n != null and n.is_room() and n.type != DungeonCell.Type.BOSS:
					room_neighbours += 1
			if room_neighbours >= 2:
				candidates.append(c)
	if candidates.is_empty():
		return
	candidates.shuffle()
	var chosen: Vector2i = candidates[0]
	layout.add_cell(chosen, DungeonCell.Type.SECRET)
	# Connect to ONE of its room neighbours — the breakable-wall side.
	var dirs := DungeonCell.DIRS.duplicate()
	dirs.shuffle()
	for d in dirs:
		var n: DungeonCell = layout.cells.get(chosen + d, null)
		if n != null and n.is_room() and n.type != DungeonCell.Type.BOSS:
			layout.connect_cells(chosen, n.coord)
			n.has_secret_hint = true
			break
	layout.compute_depths()


# -------------------------------------------------------------------------
# Day 4 — per-era theming
# -------------------------------------------------------------------------

func _apply_theme(layout: DungeonLayout) -> void:
	## Tag every cell with the era id (already true via add_cell()), then
	## look up the era's theme so the runner can read colours and props
	## without re-querying DungeonThemeRegistry per room.
	var theme_registry := get_node_or_null("/root/DungeonThemeRegistry")
	if theme_registry == null:
		return
	var theme: DungeonTheme = theme_registry.get_theme(layout.era)
	# Stash on the layout for later phases / runtime — Dictionary so we don't
	# add another field to DungeonLayout for a temporary use.
	layout.set_meta("theme", theme)
	# Set the cell era again (redundant safety belt for cells added during
	# corridor carving where add_cell() may not have set it).
	for c in layout.cells.values():
		c.era = layout.era


# -------------------------------------------------------------------------
# Day 5 — template stamping
# -------------------------------------------------------------------------

func _stamp_templates(layout: DungeonLayout) -> void:
	var library := get_node_or_null("/root/DungeonTemplateLibrary")
	if library == null:
		return
	for c in layout.cells.values():
		if not c.is_room():
			continue
		var tmpl: RoomTemplate = null
		if c.type == DungeonCell.Type.BOSS:
			# Boss rooms always try for the bespoke per-era arena first.
			tmpl = BossArenas.pick_for_era(library, layout.era, layout.rng)
		else:
			tmpl = library.pick_for(c.type, layout.rng, layout.era)
		if tmpl != null:
			c.template_id = tmpl.id


# -------------------------------------------------------------------------
# Day 6 — enemy / trap budget
# -------------------------------------------------------------------------

func _populate_rooms(layout: DungeonLayout) -> void:
	## Pre-resolve every room's "spawn plan": an array of enemy ids the room
	## will eventually spawn, plus an array of trap ids. The runtime spawner
	## reads these arrays and instantiates from res://scenes/enemies and
	## res://scenes/traps.
	var pools := EnemyTable.enemy_pools(layout.era)
	var boss_id := EnemyTable.boss_id(layout.era)
	for c in layout.cells.values():
		if not c.is_room():
			continue
		var plan := {"enemies": [], "traps": [], "boss": ""}
		match c.type:
			DungeonCell.Type.START, DungeonCell.Type.SHOP, DungeonCell.Type.SHRINE, DungeonCell.Type.SECRET:
				pass # No combat in these rooms.
			DungeonCell.Type.BOSS:
				plan["boss"] = boss_id
			DungeonCell.Type.ELITE:
				_buy_enemies(layout.rng, pools, plan, 5 + c.depth, true)
			DungeonCell.Type.NORMAL:
				_buy_enemies(layout.rng, pools, plan, 2 + c.depth, false)
		# Traps are everywhere except start/shop/shrine.
		if c.type == DungeonCell.Type.NORMAL or c.type == DungeonCell.Type.ELITE:
			var trap_budget := layout.rng.randi_range(0, 2)
			for i in trap_budget:
				var trap_pool: Array = pools.get("traps", [])
				if trap_pool.is_empty():
					continue
				plan["traps"].append(trap_pool[layout.rng.randi() % trap_pool.size()])
		c.set_meta("spawn_plan", plan)


func _buy_enemies(rng: RandomNumberGenerator, pools: Dictionary, plan: Dictionary, budget: int, allow_elites: bool) -> void:
	## Greedy budget pass: each enemy costs 1 (grunt), 2 (special), 3 (elite).
	## Keep buying until the budget is gone, weighted toward grunts so combat
	## doesn't feel like a parade of elites.
	var grunts: Array = pools.get("grunts", [])
	var specials: Array = pools.get("specials", [])
	var elites: Array = pools.get("elites", [])
	while budget > 0:
		var roll: float = rng.randf()
		var bucket: Array = grunts
		var cost: int = 1
		if allow_elites and roll < 0.20 and not elites.is_empty() and budget >= 3:
			bucket = elites
			cost = 3
		elif roll < 0.45 and not specials.is_empty() and budget >= 2:
			bucket = specials
			cost = 2
		if bucket.is_empty():
			break
		plan["enemies"].append(bucket[rng.randi() % bucket.size()])
		budget -= cost


# -------------------------------------------------------------------------
# Day 9 — loot + secret hints
# -------------------------------------------------------------------------

func _place_loot_and_secrets(layout: DungeonLayout) -> void:
	## For every cell, roll a loot plan via LootTable and stash it as cell
	## metadata. The runtime spawner reads the plan when it stamps the
	## room's `*` glyphs.
	##
	## Also walks adjacent-to-secret rooms and toggles `has_secret_hint`
	## so the template stamper can swap one regular wall glyph for a
	## breakable-wall glyph.
	for c in layout.cells.values():
		if not c.is_room():
			continue
		var plan := LootTable.plan_for(c, layout.rng)
		c.set_meta("loot_plan", plan)
		if not plan.get("drops", []).is_empty():
			c.has_loot = true

	# Re-confirm secret hint: the SECRET cell's connection neighbour is the
	# room whose wall is breakable. has_secret_hint was already set in
	# _place_secret_room(), but if the secret was removed for any reason we
	# defensively clear hints here.
	var has_secret := false
	for c in layout.cells.values():
		if c.type == DungeonCell.Type.SECRET:
			has_secret = true
			break
	if not has_secret:
		for c in layout.cells.values():
			c.has_secret_hint = false
