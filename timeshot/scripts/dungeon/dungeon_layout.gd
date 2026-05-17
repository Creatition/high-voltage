extends RefCounted
class_name DungeonLayout
## A finished dungeon: a grid of DungeonCells plus convenience accessors for
## the generator, the minimap, and the dungeon runner.
##
## The layout is generated once per era pick and lives on GameState while that
## era is being played. After the boss is killed it's discarded.

var era: String = "present"
var seed_value: int = 0
var grid_size: Vector2i = Vector2i(8, 8)
var cells: Dictionary = {}            # Vector2i -> DungeonCell
var start_coord: Vector2i = Vector2i.ZERO
var boss_coord: Vector2i = Vector2i.ZERO
var rng: RandomNumberGenerator = null


func _init(p_era: String = "present", p_seed: int = 0) -> void:
	era = p_era
	seed_value = p_seed
	rng = RandomNumberGenerator.new()
	if p_seed != 0:
		rng.seed = p_seed
	else:
		rng.randomize()
		seed_value = int(rng.seed)


func add_cell(coord: Vector2i, type: int = DungeonCell.Type.NORMAL) -> DungeonCell:
	if cells.has(coord):
		var existing: DungeonCell = cells[coord]
		existing.type = type
		return existing
	var c := DungeonCell.new()
	c.coord = coord
	c.type = type
	c.era = era
	cells[coord] = c
	return c


func get_cell(coord: Vector2i) -> DungeonCell:
	return cells.get(coord, null)


func has_room_at(coord: Vector2i) -> bool:
	var c: DungeonCell = cells.get(coord, null)
	if c == null:
		return false
	return c.is_room()


func remove_cell(coord: Vector2i) -> void:
	cells.erase(coord)


func connect_cells(a_coord: Vector2i, b_coord: Vector2i) -> void:
	var a: DungeonCell = cells.get(a_coord, null)
	var b: DungeonCell = cells.get(b_coord, null)
	if a == null or b == null:
		return
	var diff := b_coord - a_coord
	if absi(diff.x) + absi(diff.y) != 1:
		# Not orthogonally adjacent — caller bug.
		return
	a.connect_to(diff)
	b.connect_to(-diff)


func neighbours(coord: Vector2i) -> Array:
	var out: Array = []
	for d in DungeonCell.DIRS:
		var n: DungeonCell = cells.get(coord + d, null)
		if n != null:
			out.append(n)
	return out


func connected_neighbours(coord: Vector2i) -> Array:
	var out: Array = []
	var c: DungeonCell = cells.get(coord, null)
	if c == null:
		return out
	for d in c.connections:
		var n: DungeonCell = cells.get(coord + d, null)
		if n != null:
			out.append(n)
	return out


## Returns rooms (excludes corridors and empty cells).
func rooms() -> Array:
	var out: Array = []
	for c in cells.values():
		if c.is_room():
			out.append(c)
	return out


func room_count() -> int:
	return rooms().size()


func find_rooms_of_type(t: int) -> Array:
	var out: Array = []
	for c in cells.values():
		if c.type == t:
			out.append(c)
	return out


## BFS depth from start. Cells with no path stay at -1.
func compute_depths() -> void:
	for c in cells.values():
		c.depth = -1
	var start: DungeonCell = cells.get(start_coord, null)
	if start == null:
		return
	start.depth = 0
	var queue: Array[Vector2i] = [start_coord]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_front()
		var cur: DungeonCell = cells.get(here, null)
		if cur == null:
			continue
		for d in cur.connections:
			var nc: DungeonCell = cells.get(here + d, null)
			if nc == null:
				continue
			if nc.depth >= 0:
				continue
			nc.depth = cur.depth + 1
			queue.push_back(nc.coord)


## Furthest cell reachable from start. Used to place the boss.
func furthest_room() -> DungeonCell:
	var best: DungeonCell = null
	for c in cells.values():
		if not c.is_room():
			continue
		if c.depth < 0:
			continue
		if best == null or c.depth > best.depth:
			best = c
	return best


func to_string_grid() -> String:
	## Debug ASCII rendering. Useful when generator output looks wrong.
	if cells.is_empty():
		return "(empty)"
	var first: Vector2i = cells.keys()[0]
	var min_xy: Vector2i = first
	var max_xy: Vector2i = first
	for c in cells.values():
		min_xy.x = mini(min_xy.x, c.coord.x)
		min_xy.y = mini(min_xy.y, c.coord.y)
		max_xy.x = maxi(max_xy.x, c.coord.x)
		max_xy.y = maxi(max_xy.y, c.coord.y)
	var lines: Array[String] = []
	for y in range(min_xy.y, max_xy.y + 1):
		var line := ""
		for x in range(min_xy.x, max_xy.x + 1):
			var c: DungeonCell = cells.get(Vector2i(x, y), null)
			if c == null:
				line += "."
			else:
				match c.type:
					DungeonCell.Type.START:    line += "S"
					DungeonCell.Type.BOSS:     line += "B"
					DungeonCell.Type.SHOP:     line += "$"
					DungeonCell.Type.SHRINE:   line += "+"
					DungeonCell.Type.SECRET:   line += "?"
					DungeonCell.Type.ELITE:    line += "E"
					DungeonCell.Type.NORMAL:   line += "#"
					DungeonCell.Type.CORRIDOR: line += "-"
					_:                          line += "."
		lines.append(line)
	return "\n".join(lines)
