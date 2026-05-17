extends RefCounted
class_name BossArenas
## Bespoke boss arena templates — one per era. Generator routes the
## furthest-from-start cell to one of these instead of the generic
## "boss_open" fallback.
##
## Each arena is a RoomTemplate with the BOSS room type and an extra `tags`
## entry containing the era id. The DungeonTemplateLibrary registers these
## on _ready(), but they live here so the data is easy to find when an
## arena needs tweaking.

static func all() -> Array:
	var out: Array = []

	# --- Prehistoric: T-rex stomping arena ---
	out.append(RoomTemplate.new("trex_arena", DungeonCell.Type.BOSS, [
		"########################",
		"#......................#",
		"#......T........T......#",
		"#..........B...........#",
		"<......................>",
		"#..........*...........#",
		"#......T........T......#",
		"#......................#",
		"########################",
	], ["prehistoric", "boss"]))

	# --- Medieval: Black Knight throne hall ---
	out.append(RoomTemplate.new("black_knight_arena", DungeonCell.Type.BOSS, [
		"##########################",
		"#........................#",
		"#..p..................p..#",
		"#........................#",
		"#...........B............#",
		"<........................>",
		"#...........*............#",
		"#..p..................p..#",
		"##########################",
	], ["medieval", "boss"]))

	# --- Future / Cyberpunk: AI Core data hall ---
	out.append(RoomTemplate.new("ai_core_arena", DungeonCell.Type.BOSS, [
		"##############################",
		"#............................#",
		"#..#####............#####....#",
		"#............................#",
		"#..............B.............#",
		"<............................>",
		"#..............*.............#",
		"#..#####............#####....#",
		"#............................#",
		"##############################",
	], ["future", "cyberpunk", "boss"]))

	# --- Alien: Mothership organic dome ---
	out.append(RoomTemplate.new("mothership_arena", DungeonCell.Type.BOSS, [
		"##############################",
		"#............................#",
		"#......p..............p......#",
		"#............................#",
		"#..............B.............#",
		"<............................>",
		"#..........*..........*......#",
		"#......p..............p......#",
		"#............................#",
		"##############################",
	], ["alien", "boss"]))

	# --- Present: Miniboss alley ---
	out.append(RoomTemplate.new("present_boss_arena", DungeonCell.Type.BOSS, [
		"##############################",
		"#............................#",
		"#..p..p..............p..p....#",
		"#............................#",
		"#..............B.............#",
		"<............................>",
		"#..............*.............#",
		"#..p..p..............p..p....#",
		"#............................#",
		"##############################",
	], ["present", "boss"]))

	# --- Aztec: Jade ritual platform ---
	out.append(RoomTemplate.new("aztec_priest_arena", DungeonCell.Type.BOSS, [
		"##########################",
		"#........................#",
		"#....TT............TT....#",
		"#........................#",
		"#...........B............#",
		"<........................>",
		"#...........*............#",
		"#....TT............TT....#",
		"##########################",
	], ["aztec", "boss"]))

	# --- Egypt: Mummy lord burial chamber ---
	out.append(RoomTemplate.new("mummy_lord_arena", DungeonCell.Type.BOSS, [
		"##########################",
		"#........................#",
		"#..p..p..........p..p....#",
		"#........................#",
		"#...........B............#",
		"<........................>",
		"#..p..*..........*..p....#",
		"#........................#",
		"##########################",
	], ["egypt", "boss"]))

	return out


## Picks the most specific bespoke arena for the era; falls back to the
## generic boss_open template if no match is found.
static func pick_for_era(library: Node, era_id: String, rng: RandomNumberGenerator) -> RoomTemplate:
	var matches: Array = []
	for t in library.templates:
		if t.room_type != DungeonCell.Type.BOSS:
			continue
		if era_id in t.tags:
			matches.append(t)
	if matches.is_empty():
		return library.pick_for(DungeonCell.Type.BOSS, rng, era_id)
	return matches[rng.randi() % matches.size()]
