extends Node
## Stateful "player is currently inside generated dungeon X at room Y" tracker.
##
## Sits alongside GameState (which still owns the legacy linear dungeon_queue
## for eras that haven't been migrated to procgen). When start_generated_era()
## is called, the runner takes over: it generates a layout, sets the current
## room to the START cell, and routes door transitions through neighbour
## lookups instead of the linear queue.
##
## The door scene already has a fallback path that calls GameState.next_room_path(),
## so the migration is opt-in: an era is "procgen-enabled" once its room
## scenes call DungeonRunner.advance_through(direction).

signal dungeon_started(era: String)
signal room_entered(coord: Vector2i)
signal dungeon_completed(era: String)

var active: bool = false
var layout: DungeonLayout = null
var current_coord: Vector2i = Vector2i.ZERO
var visited: Dictionary = {}     # Vector2i -> true


func start_generated_era(era_id: String, seed_value: int = 0) -> void:
	var gen := get_node_or_null("/root/DungeonGenerator")
	if gen == null:
		push_error("DungeonRunner: DungeonGenerator autoload missing.")
		return
	layout = gen.generate(era_id, seed_value)
	active = true
	current_coord = layout.start_coord
	visited.clear()
	visited[current_coord] = true
	var start_cell: DungeonCell = layout.get_cell(current_coord)
	if start_cell != null:
		start_cell.visited = true
	dungeon_started.emit(era_id)
	room_entered.emit(current_coord)


func stop() -> void:
	active = false
	layout = null
	visited.clear()


func current_cell() -> DungeonCell:
	if layout == null:
		return null
	return layout.get_cell(current_coord)


## Move from the current cell through `direction` (one of DungeonCell.DIRS).
## Returns the destination cell or null if no connection exists in that
## direction.
func advance_through(direction: Vector2i) -> DungeonCell:
	if not active or layout == null:
		return null
	var cur: DungeonCell = layout.get_cell(current_coord)
	if cur == null:
		return null
	if not cur.is_connected_to(direction):
		return null
	var next_coord: Vector2i = current_coord + direction
	var next_cell: DungeonCell = layout.get_cell(next_coord)
	if next_cell == null:
		return null
	# Skip corridors transparently — corridors are one-cell connectors with
	# exactly two endpoints. Walk through them until we hit a room cell.
	while next_cell != null and next_cell.type == DungeonCell.Type.CORRIDOR:
		# pick the OTHER endpoint of the corridor (the one we didn't come from)
		var exit_dir: Vector2i = direction
		for d in next_cell.connections:
			if d != -direction:
				exit_dir = d
				break
		direction = exit_dir
		next_coord = next_coord + exit_dir
		next_cell = layout.get_cell(next_coord)
	if next_cell == null:
		return null
	current_coord = next_cell.coord
	visited[current_coord] = true
	next_cell.visited = true
	room_entered.emit(current_coord)
	if next_cell.type == DungeonCell.Type.BOSS:
		# Boss kills will fire dungeon_completed via mark_complete().
		pass
	return next_cell


func mark_current_complete() -> void:
	## Called by procgen rooms when their clear logic fires. If we just
	## cleared the boss, the run advances out of this era.
	var c: DungeonCell = current_cell()
	if c == null:
		return
	if c.type == DungeonCell.Type.BOSS:
		dungeon_completed.emit(layout.era)


func connection_dirs_from_current() -> Array:
	var c: DungeonCell = current_cell()
	if c == null:
		return []
	return c.connections.duplicate()


## Helper for door scenes: given the door's "exit direction", call advance.
## Direction is one of "north"/"east"/"south"/"west".
func advance_named(direction_name: String) -> DungeonCell:
	match direction_name.to_lower():
		"north", "up":    return advance_through(DungeonCell.DIR_NORTH)
		"east", "right":  return advance_through(DungeonCell.DIR_EAST)
		"south", "down":  return advance_through(DungeonCell.DIR_SOUTH)
		"west", "left":   return advance_through(DungeonCell.DIR_WEST)
	return null
