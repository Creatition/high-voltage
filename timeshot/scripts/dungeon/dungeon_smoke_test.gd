extends SceneTree
## Headless smoke test: spin every era through the generator and assert the
## layout makes basic sense (start exists, boss exists, room count in range,
## graph is connected). Run with:
##
##   godot --headless --script res://scripts/dungeon/dungeon_smoke_test.gd
##
## Used as the Day 10 verification pass. Useful to re-run any time the
## generator's tunables are changed.

const ERAS := ["present", "prehistoric", "medieval", "future", "alien",
				"aztec", "egypt"]


func _init() -> void:
	var failures: Array[String] = []
	for era in ERAS:
		var fail := _test_era(era)
		if fail != "":
			failures.append("[%s] %s" % [era, fail])
	if failures.is_empty():
		print("dungeon_smoke_test: ALL OK across %d eras." % ERAS.size())
	else:
		printerr("dungeon_smoke_test: %d failures" % failures.size())
		for f in failures:
			printerr("  ", f)
	quit()


func _test_era(era: String) -> String:
	# Use a fixed seed per era so failures reproduce.
	var seed_value := 1000 + abs(era.hash() % 9999)
	var generator = root.get_node_or_null("DungeonGenerator")
	if generator == null:
		# When running with `--script` the autoloads aren't attached, so we
		# instantiate directly.
		var GenScript = load("res://scripts/autoload/dungeon_generator.gd")
		generator = GenScript.new()
		root.add_child(generator)
		var ThemeScript = load("res://scripts/autoload/dungeon_theme_registry.gd")
		var theme = ThemeScript.new()
		theme.name = "DungeonThemeRegistry"
		root.add_child(theme)
		var LibScript = load("res://scripts/autoload/dungeon_template_library.gd")
		var lib = LibScript.new()
		lib.name = "DungeonTemplateLibrary"
		root.add_child(lib)
	var layout = generator.generate(era, seed_value)
	if layout == null:
		return "generator returned null layout"
	if layout.room_count() < 5:
		return "only %d rooms" % layout.room_count()
	if layout.room_count() > 18:
		return "too many rooms: %d" % layout.room_count()
	var bosses = layout.find_rooms_of_type(DungeonCell.Type.BOSS)
	if bosses.is_empty():
		return "no BOSS cell"
	var starts = layout.find_rooms_of_type(DungeonCell.Type.START)
	if starts.is_empty():
		return "no START cell"
	# Connectivity check.
	var reached: Dictionary = {}
	var stack: Array = [layout.start_coord]
	while not stack.is_empty():
		var here = stack.pop_back()
		if reached.has(here):
			continue
		reached[here] = true
		var cur = layout.cells.get(here, null)
		if cur == null:
			continue
		for d in cur.connections:
			stack.push_back(here + d)
	for r in layout.rooms():
		if not reached.has(r.coord) and r.type != DungeonCell.Type.SECRET:
			return "room %s unreachable (type=%s)" % [str(r.coord), r.type_name()]
	return ""
