extends Node
## Lookup table that maps era_id -> DungeonTheme.
##
## Each entry is a recipe: colours, tile/prop scene ids, an ambient track id,
## and the bespoke boss-arena template (so the generator can drop into a
## hand-designed boss room at depth-furthest).

var themes: Dictionary = {}    # era_id -> DungeonTheme


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	themes.clear()
	_register("present",
		Color(0.45, 0.45, 0.50),
		Color(0.20, 0.20, 0.24),
		Color(0.55, 0.85, 1.00),
		"present_tile",
		["traffic_cone", "trashcan", "newspaper_stand"],
		"present_boss_arena",
		"Concrete plazas, cop sirens, distant chopper rotor.")

	_register("prehistoric",
		Color(0.42, 0.34, 0.24),
		Color(0.22, 0.18, 0.14),
		Color(0.65, 0.85, 0.35),
		"prehistoric_tile",
		["fern", "bone_pile", "tar_pool"],
		"trex_arena",
		"Volcanic ash, tar pools, the ground vibrates when something big walks.")

	_register("medieval",
		Color(0.50, 0.46, 0.40),
		Color(0.28, 0.24, 0.22),
		Color(0.78, 0.70, 0.55),
		"medieval_tile",
		["torch", "barrel", "banner"],
		"black_knight_arena",
		"Torch-lit halls, banners on stone, plate boots ringing on flagstone.")

	_register("future",
		Color(0.30, 0.36, 0.48),
		Color(0.16, 0.18, 0.26),
		Color(0.55, 0.95, 0.85),
		"cyberpunk_tile",
		["holo_billboard", "server_rack", "neon_strip"],
		"ai_core_arena",
		"Neon rain on glass, holograms half-buried in static.")

	_register("alien",
		Color(0.38, 0.30, 0.50),
		Color(0.18, 0.14, 0.26),
		Color(0.55, 1.00, 0.45),
		"alien_tile",
		["xeno_pod", "bioluminescent_vine", "drone_shell"],
		"mothership_arena",
		"Pulsing organic floor. Things in the walls are watching.")

	_register("aztec",
		Color(0.38, 0.42, 0.30),
		Color(0.22, 0.26, 0.18),
		Color(0.30, 0.85, 0.55),
		"aztec_tile",
		["obsidian_idol", "vine", "ritual_brazier"],
		"aztec_priest_arena",
		"Jade glyphs, jaguar carvings, the floor is humming.")

	_register("egypt",
		Color(0.62, 0.54, 0.36),
		Color(0.30, 0.26, 0.18),
		Color(0.95, 0.80, 0.30),
		"sandstone_tile",
		["sarcophagus", "scarab_shrine", "anubis_statue"],
		"mummy_lord_arena",
		"Sandstone hallways. Every door is a trap until proved otherwise.")


func _register(era: String, floor_c: Color, wall_c: Color, accent_c: Color,
		tile_id: String, props: Array, boss_arena: String, desc: String) -> void:
	var t := DungeonTheme.new(era)
	t.floor_color = floor_c
	t.wall_color = wall_c
	t.accent_color = accent_c
	t.tile_scene_id = tile_id
	for p in props:
		t.prop_scene_ids.append(String(p))
	t.boss_arena_template = boss_arena
	t.description = desc
	themes[era] = t


func get_theme(era_id: String) -> DungeonTheme:
	if themes.has(era_id):
		return themes[era_id]
	# Sensible fallback so generators never crash on unknown eras.
	return themes.get("present", DungeonTheme.new("present"))
