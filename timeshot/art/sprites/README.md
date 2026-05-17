# Timeshot Sprite Manifest

All sprites are pixel-art PNGs with alpha. Style: bold black outlines, bright fills, 1-px highlight + shadow. Designed for nearest-neighbor filtering (set globally in `project.godot`).

Animations are exported as **horizontal spritesheets** — slice them with `region_enabled = true` + `hframes = N`, or import each sheet into an `AnimatedSprite2D`'s `SpriteFrames` resource.

## Sizes

| Category | Size | Frames per sheet |
|---|---|---|
| Characters (player + roster) | 32×32 | 1 (shoot) or 4 (idle/run/dodge) |
| Character portraits | 48×48 | 1 |
| Enemies | 32×32 | 1 or 4 |
| Bosses | 64×64 | 4 |
| Projectiles | 8×8 to 16×8 | 1; explosion = 7 |
| Pickups | 12×12 or 16×16 | 1 or 4 |
| Tiles | 16×16 | 1 |
| UI elements | 8×8 to 48×64 | 1 |
| Traps | 16×16 or 32×32 | 1 |
| Weapons | 24×16 | 1 |

## Folders

```
characters/  hero, rogue, gunslinger, scientist, knight, alien
             — each has _idle, _run, _dodge (4f each), _shoot (1f), _portrait (1f)
             hero/gunslinger/scientist additionally have
             _idle_up/_run_up, _idle_down/_run_down, _idle_side/_run_side
enemies/     drone, hacker, shooter, chaser (present)
             knight, archer (medieval)
             raptor, pterodactyl, caveman (prehistoric)
             alien_grunt, alien_sentry (alien)
             aztec_warrior (aztec)
             dummy (training)
bosses/      present_miniboss, black_knight, trex,
             alien_mothership, ai_core, aztec_boss
projectiles/ player_bullet, enemy_bullet, plasma_bolt, arrow, explosion
pickups/     time_shard (4f), coin_gold/silver/copper, heart
tiles/       <era>_floor.png, <era>_wall.png, <era>_autotile.png (16-tile sheet)
             for present, medieval, prehistoric, cyberpunk, alien, aztec
weapons/     pistol_<era>.png — chrono-pistol skin per era
ui/          heart_full, heart_empty, upgrade_card_frame, button,
             crosshair, minimap_room, title_logo, menu_bg,
             card_<type> (fire/ice/shock/poison/speed/vitality/shield/power/multishot/boom),
             era_icon_<era>, bar_health_*, bar_xp_*, bar_dodge,
             ammo_dot_full/empty/reload, run_end_victory/defeat
traps/       spike_pit, pressure_plate, dart_shooter
hub/         time_machine, portal_<era>
props/       door_<kind>_<state>, chest_open/closed,
             shop_terminal, reward_shrine, workbench
npcs/        mechanic, shopkeeper, sage, outlaw, raptor_pet (idle sheets)
vfx/         muzzle_flash (+_big), dodge_poof, hit_spark (+_ice/_plasma),
             blood_splatter, dust_puff, teleport
icons/       status_burn/freeze/poison/shock/slow/shield
decor/       crate, pot_<material>, column_<era>, bush_prehistoric,
             skull, neon_screen, computer_terminal, totem_aztec,
             banner_red/blue/green, crystal_cluster_alien, torch (4f)
```

## Autotile layout

Each `<era>_autotile.png` is a 64×64 sheet (4×4 grid of 16×16 cells):

```
TL  T   TR  .
L   C   R   .
BL  B   BR  .
v0  v1  v2  v3       (center variations)
```

Slice with `region_enabled = true`, `region_rect = Rect2(col*16, row*16, 16, 16)`
or wire as a Godot 4 TileSet with terrain sets.

## Wiring example (player)

`scenes/player/player.tscn` now uses `art/sprites/characters/hero_shoot.png` as the static sprite. To swap to animated:

```gdscript
# replace Sprite2D with AnimatedSprite2D and create a SpriteFrames
# with hframes=4 over hero_idle.png / hero_run.png / hero_dodge.png
```

## Regenerating

The sprites were generated programmatically by the Python scripts in `outputs/day1_player.py` through `day5_props.py` (see High Voltage workspace outputs). Re-run any of them to regenerate. The shared helpers are in `outputs/spritegen.py`.
