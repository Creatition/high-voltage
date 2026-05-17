# Timeshot (Godot 4 project)

Time-travel bullet-hell roguelike. Solo-dev project. See `../game_design.md` for the full design doc.

## Open in Godot

1. Install Godot 4.2 or later (https://godotengine.org/download).
2. In Godot, click `Import` and select the `project.godot` file in this folder.
3. Press F5 to run. The main scene is `scenes/main.tscn`.

## Project structure

```
timeshot/
├── addons/                  Third-party plugins (GodotSteam, etc.)
├── art/
│   ├── sprites/             PNGs / Aseprite exports
│   │   ├── characters/      Player + unlockable roster
│   │   ├── enemies/         Era enemy sprites
│   │   ├── bosses/          Boss forms per era
│   │   ├── weapons/         Chrono-Pistol skins per era + upgrade visuals
│   │   ├── projectiles/     Bullets, explosions
│   │   ├── tiles/           Tilesets for room generation
│   │   └── ui/              HUD, menus, upgrade cards
│   ├── animations/          SpriteFrames resources
│   └── shaders/             GLSL/Godot shaders (palette swap, hit flash)
├── audio/
│   ├── music/               .ogg / .wav music tracks
│   └── sfx/                 Gunshots, explosions, ambience
├── scenes/                  .tscn scene files, grouped by domain
│   ├── player/
│   ├── weapons/
│   ├── projectiles/
│   ├── enemies/
│   ├── bosses/
│   ├── rooms/               Individual room templates
│   ├── dungeons/            Era dungeons + procedural generators
│   ├── hub/                 Time machine hub
│   ├── ui/                  Menus, HUD, upgrade picker
│   └── debug/               Test scenes for prototyping
├── scripts/
│   ├── autoload/            Singletons (game state, input, audio)
│   ├── components/          Reusable components (health, hitbox, hurtbox)
│   └── utils/               Helper functions, constants
├── resources/               Custom Resource subclasses (.tres files)
│   ├── upgrades/            Upgrade data resources
│   ├── enemies/             Enemy stat resources
│   └── characters/          Character data resources
├── icon.svg                 Project icon (placeholder)
└── project.godot            Engine config
```

## Architecture conventions

- **Input actions are abstract.** Never check raw keycodes or button indices in gameplay code — always go through `Input.is_action_pressed("dodge")` etc. Bindings are defined in `scripts/autoload/input_manager.gd` and will be moved to user-rebindable config later.
- **Components over inheritance.** Health, hitbox, hurtbox, and similar mechanics are nodes you attach to entities, not parent classes. Makes it easy to mix-and-match (enemies, bosses, destructible props all share a HealthComponent).
- **Data in Resources.** Upgrade cards, enemy stats, character starting kits live as `.tres` files in `resources/`. Designers (you) can tweak numbers without touching code.
- **Pixel-perfect 2D.** Default texture filter is set to nearest-neighbor in `project.godot`. Sprites import at 32×32 base; larger for bosses.

## Scaffolding status

Currently included:
- Project config + autoloads registered
- Input map registered programmatically by `InputManager` (move, shoot, dodge, interact, pause)
- Player scene with movement + dodge roll + aim + shoot (placeholder projectile)
- Main test scene with one Player instance and a camera
- Component stubs (HealthComponent, HitboxComponent, HurtboxComponent)

Next steps for the prototype slice:
- One projectile scene + script
- Three enemy types (charger, shooter, skirmisher)
- One procedural room generator
- One mini-boss
- Hub scene with workbench + currency persistence
