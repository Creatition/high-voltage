# Dungeon Generation (Days 1–10)

This pass added procedural dungeon generation to Timeshot. Each era pick
now produces a fresh dungeon graph instead of pulling from a fixed linear
queue of room scenes.

## File map

```
scripts/autoload/
  dungeon_generator.gd        Autoload: generate(era, seed) -> DungeonLayout
  dungeon_runner.gd           Autoload: tracks active dungeon + current cell
  dungeon_theme_registry.gd   Autoload: era_id -> DungeonTheme
  dungeon_template_library.gd Autoload: hand-authored RoomTemplates

scripts/dungeon/
  dungeon_cell.gd             Single grid cell (type, connections, depth)
  dungeon_layout.gd           Grid + cells + connectivity helpers
  dungeon_theme.gd            Per-era palette / props / boss arena
  room_template.gd            Hand-authored glyph-grid room layout
  bsp_partitioner.gd          Recursive BSP region splitter
  enemy_table.gd              Era -> enemy pools (grunts/specials/elites/traps)
  loot_table.gd               Per-cell loot rolls (shard/heart/upgrade/chest)
  boss_arenas.gd              Bespoke boss arena templates per era
  dungeon_smoke_test.gd       Headless smoke test (Day 10)

scenes/rooms/
  breakable_wall.gd           Wall the player can shoot down to reach a SECRET
scenes/ui/
  graph_minimap.gd            Minimap that renders the generated graph
```

## Pipeline

```
generate(era, seed)
  -> _place_rooms       Day 2  BSP + walker + L-bend corridors
  -> _tag_special_rooms Day 3  START / BOSS / SHOP / SHRINE / ELITE / SECRET
  -> _apply_theme       Day 4  Stash DungeonTheme on layout
  -> _stamp_templates   Day 5  Pick a RoomTemplate per cell (bespoke for BOSS)
  -> _populate_rooms    Day 6  Enemy/trap budget per cell (depth-scaled)
  -> _place_loot_...    Day 9  LootTable rolls + secret hint placement
```

## Tunables

All on `DungeonGenerator` autoload — adjustable from the inspector or via
script for live tuning during playtests:

| Variable               | Default | Effect                                |
| ---------------------- | ------- | ------------------------------------- |
| rooms_per_era_min      | 7       | floor on room count                   |
| rooms_per_era_max      | 11      | ceiling on room count                 |
| grid_size              | 9x9     | bounds of the layout grid             |
| bsp_max_depth          | 3       | BSP recursion depth (~8 leaves)       |
| elite_room_chance      | 0.20    | per-normal-room elite upgrade roll    |
| shop_room_chance       | 0.85    | chance there's a shop this dungeon    |
| shrine_room_chance     | 0.75    | chance there's a shrine this dungeon  |
| secret_room_chance     | 0.55    | chance there's a secret this dungeon  |

## Smoke test

```
godot --headless --script res://scripts/dungeon/dungeon_smoke_test.gd
```

Iterates every era through the generator with deterministic seeds and
fails the build if any layout breaks the basic invariants (start exists,
boss exists, room count in range, graph is connected).

## Migration plan (post-day 10)

The legacy linear pipeline (`GameState.dungeon_queue` + `EraRegistry`) still
works for any era that hasn't been migrated to procgen. To migrate an era:

1. Replace the era's `start_era` callsite with
   `DungeonRunner.start_generated_era(era_id, seed_value)`.
2. Update the era's door scenes to call `DungeonRunner.advance_named(dir)`
   instead of relying on `next_scene_path`.
3. Make sure the era has at least one bespoke boss arena registered in
   `BossArenas.all()` (or the generator will fall back to `boss_open`).
