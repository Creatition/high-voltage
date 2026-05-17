extends RefCounted
class_name DungeonDebug
## Tiny developer helpers for inspecting generated dungeons at runtime.
##
## Usage in any script with access to the runner:
##   DungeonDebug.dump_layout(DungeonRunner.layout)
##   DungeonDebug.summary(DungeonRunner.layout)

static func dump_layout(layout: DungeonLayout) -> void:
	if layout == null:
		print("DungeonDebug: layout is null")
		return
	print("[%s seed=%d] %d rooms, boss=%s" % [
		layout.era, layout.seed_value, layout.room_count(), str(layout.boss_coord)])
	print(layout.to_string_grid())


static func summary(layout: DungeonLayout) -> String:
	if layout == null:
		return "(null layout)"
	var counts := {}
	for c in layout.rooms():
		counts[c.type_name()] = counts.get(c.type_name(), 0) + 1
	var parts: Array[String] = []
	for k in counts.keys():
		parts.append("%s=%d" % [k, counts[k]])
	return "era=%s seed=%d rooms=%d (%s)" % [
		layout.era, layout.seed_value, layout.room_count(), ", ".join(parts)]


static func print_player_path(layout: DungeonLayout) -> void:
	## BFS from start, print depth of every reachable room. Useful for
	## tuning rooms_per_era_max — if the longest path is < 4 the dungeons
	## feel too small; if > 12 they feel grindy.
	if layout == null:
		return
	var deepest := 0
	for c in layout.rooms():
		deepest = maxi(deepest, c.depth)
		print("  %s @ %s depth=%d" % [c.type_name(), str(c.coord), c.depth])
	print("DungeonDebug: deepest reachable room depth = %d" % deepest)
