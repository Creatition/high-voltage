# High Voltage

Studio repo for solo-dev game projects. Currently houses **Timeshot**.

## Projects

- **`timeshot/`** — Godot 4 project. Time-travel bullet-hell roguelike. See `timeshot/README.md` for setup, and `game_design.md` for the full design doc.

## Repo layout

```
high-voltage/
├── game_design.md      Living design doc for Timeshot
├── timeshot/           Godot 4 project root — open this in Godot
├── README.md           This file
└── .gitignore          Includes Godot, OS, and tooling ignores
```

## Workflow

- Design changes go in `game_design.md`.
- Godot work happens inside `timeshot/`. Open `timeshot/project.godot` in Godot 4.2+.
- Commit and push after meaningful changes.
