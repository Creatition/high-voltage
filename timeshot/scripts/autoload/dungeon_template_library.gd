extends Node
## A small library of hand-authored RoomTemplates, indexed by room type and
## optionally by era tag.
##
## Templates are written as text grids inline — quick to author, easy to read,
## no .tscn busy-work. The runtime spawner converts glyphs to Node2D children
## at stamping time (Day 7).
##
## Adding a template:
##   _add(RoomTemplate.new("normal_pillars", DungeonCell.Type.NORMAL, [
##       "############",
##       "#....##....#",
##       "#.e..##..e.#",
##       "<...........>",
##       "#.e..##..e.#",
##       "#....##....#",
##       "############",
##   ], ["any"]))

var templates: Array = []     # Array[RoomTemplate]


func _ready() -> void:
	_register_all()


func count() -> int:
	return templates.size()


func _register_all() -> void:
	templates.clear()
	_register_start_rooms()
	_register_normal_rooms()
	_register_elite_rooms()
	_register_shop_rooms()
	_register_shrine_rooms()
	_register_boss_rooms()
	_register_secret_rooms()
	_register_bespoke_boss_arenas()


func _register_bespoke_boss_arenas() -> void:
	for arena in BossArenas.all():
		_add(arena)


# ---- Start rooms ---------------------------------------------------------

func _register_start_rooms() -> void:
	_add(RoomTemplate.new("start_open", DungeonCell.Type.START, [
		"############",
		"#..........#",
		"#..........#",
		"<....P....>",
		"#..........#",
		"#..........#",
		"############",
	], ["any"]))
	_add(RoomTemplate.new("start_pillars", DungeonCell.Type.START, [
		"##############",
		"#............#",
		"#..#......#..#",
		"<....P.....>",
		"#..#......#..#",
		"#............#",
		"##############",
	], ["any"]))


# ---- Normal combat rooms -------------------------------------------------

func _register_normal_rooms() -> void:
	_add(RoomTemplate.new("normal_quad", DungeonCell.Type.NORMAL, [
		"############",
		"#..e....e..#",
		"#..........#",
		"<....p.....>",
		"#..........#",
		"#..e....e..#",
		"############",
	], ["any"]))
	_add(RoomTemplate.new("normal_corridor", DungeonCell.Type.NORMAL, [
		"#################",
		"#...............#",
		"#.e.T.....T.e..#",
		"<...............>",
		"#.e.T.....T.e..#",
		"#...............#",
		"#################",
	], ["any"]))
	_add(RoomTemplate.new("normal_arena", DungeonCell.Type.NORMAL, [
		"##############",
		"#....e.e....#",
		"#..........e#",
		"<.....p.....>",
		"#e..........#",
		"#....e.e....#",
		"##############",
	], ["any"]))
	_add(RoomTemplate.new("normal_pillars", DungeonCell.Type.NORMAL, [
		"##############",
		"#.e..##.e....#",
		"#....##......#",
		"<......*.....>",
		"#....##......#",
		"#.e..##.e....#",
		"##############",
	], ["any"]))
	_add(RoomTemplate.new("normal_pit", DungeonCell.Type.NORMAL, [
		"##############",
		"#............#",
		"#.e..TTT...e.#",
		"<....TTT......>",
		"#.e..TTT...e.#",
		"#............#",
		"##############",
	], ["any"]))


# ---- Elite rooms ---------------------------------------------------------

func _register_elite_rooms() -> void:
	_add(RoomTemplate.new("elite_squad", DungeonCell.Type.ELITE, [
		"################",
		"#..............#",
		"#..E........E..#",
		"<.....p........>",
		"#..E........E..#",
		"#..............#",
		"################",
	], ["any"]))
	_add(RoomTemplate.new("elite_choke", DungeonCell.Type.ELITE, [
		"################",
		"#.......##.....#",
		"#.E.....##..E..#",
		"<.......##......>",
		"#.E.....##..E..#",
		"#.......##.....#",
		"################",
	], ["any"]))


# ---- Shop rooms ---------------------------------------------------------

func _register_shop_rooms() -> void:
	_add(RoomTemplate.new("shop_cozy", DungeonCell.Type.SHOP, [
		"############",
		"#..........#",
		"#....$.....#",
		"<..........>",
		"#..p....p..#",
		"#..........#",
		"############",
	], ["any"]))


# ---- Shrine rooms -------------------------------------------------------

func _register_shrine_rooms() -> void:
	_add(RoomTemplate.new("shrine_circle", DungeonCell.Type.SHRINE, [
		"############",
		"#....##....#",
		"#..........#",
		"<....+.....>",
		"#..........#",
		"#....##....#",
		"############",
	], ["any"]))


# ---- Boss rooms ---------------------------------------------------------

func _register_boss_rooms() -> void:
	## Most bosses get bespoke arenas (Day 8). This fallback covers eras
	## that don't have one yet.
	_add(RoomTemplate.new("boss_open", DungeonCell.Type.BOSS, [
		"##################",
		"#................#",
		"#................#",
		"#.......B........#",
		"<................>",
		"#................#",
		"#................#",
		"##################",
	], ["any"]))


# ---- Secret rooms -------------------------------------------------------

func _register_secret_rooms() -> void:
	_add(RoomTemplate.new("secret_treasure", DungeonCell.Type.SECRET, [
		"##########",
		"#........#",
		"#..*..*..#",
		"x...+....#",
		"#..*..*..#",
		"#........#",
		"##########",
	], ["any"]))


# -------------------------------------------------------------------------

func _add(template: RoomTemplate) -> void:
	templates.append(template)


func pick_for(room_type: int, rng: RandomNumberGenerator, era_id: String = "any") -> RoomTemplate:
	var pool: Array = []
	for t in templates:
		if t.room_type != room_type:
			continue
		if "any" in t.tags or era_id in t.tags:
			pool.append(t)
	if pool.is_empty():
		# Fall back to first matching room_type, ignoring tags.
		for t in templates:
			if t.room_type == room_type:
				pool.append(t)
	if pool.is_empty():
		return null
	return pool[rng.randi() % pool.size()]


func by_id(id: String) -> RoomTemplate:
	for t in templates:
		if t.id == id:
			return t
	return null
