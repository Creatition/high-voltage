# Timeshot — Game Design Doc

> Top-down bullet-hell roguelike with a time-travel chase. Solo dev, Godot 4, stylized pixel art.

## Elevator pitch

You stumble onto a time machine in the present day, just as a thief — *the final boss* — uses it to escape into history. You chase them through five eras: **Prehistoric, Ancient Egypt, Wild West, Future, and back to the Present**. Each era is a Gungeon-style procedurally generated run with its own enemies, traps, and weapons aesthetic, and ends with a fight against an era-fused form of the boss who escapes deeper into time. The final fight takes place in a Present Day overwritten by the boss's meddling.

## Core pillars

1. **One gun, infinite variations.** The player has a single signature weapon, the **Chrono-Pistol**, that evolves dramatically through Rounds-style modular upgrades.
2. **Time as theme, not gimmick.** Each era is a self-contained mini-game with unique mechanics, but they all interlock through the chase narrative and the gun.
3. **Player power persists, gear does not.** Money is spent on the *player*, not on disposable inventory. No hoarding.
4. **The chase tells the story.** You confront an evolved form of the same boss at the end of every era. They escape, taking one of your upgrades with them. You follow. Each encounter reveals more of their plan.

## Era flow

| # | Era | Role | Aesthetic | Theme weapons |
|---|---|---|---|---|
| 0 | **Present Day** | Tutorial + framing | Neutral gray/blue, urban | Modern pistol |
| 1-4 | **Prehistoric** | Era pool | Green/orange/brown jungle | Bone, stone |
| 1-4 | **Ancient Egypt** | Era pool | Sand gold + teal, pyramids | Khopesh, golden gun |
| 1-4 | **Wild West** | Era pool | Sepia/red/brown desert | Six-shooter, lever-action |
| 1-4 | **Future** | Era pool | Cyan/magenta/black neon | Plasma, railgun |
| 5 | **Corrupted Present** | Finale | Glitched/warped version of Era 0 | All previous fused |

After completing the Present (Era 0), the player returns to the **time machine hub** and **chooses the next era**. Difficulty scales with how many eras you've cleared, not which one you pick. After all four mid-eras are cleared, you return to a corrupted Present for the final fight.

## The Chrono-Pistol

The player keeps **one weapon** for the entire run. It starts as a plain pistol. Through era shops and boss-room drops, you stack modular upgrades that change behavior dramatically:

- **Fire mode:** semi-auto → burst → full-auto → charge shot → shotgun spread → beam
- **Bullets:** standard → bouncing → homing → piercing → explosive → splitting → ricochet → chain lightning
- **Modifiers:** crit chance, lifesteal, status effects (bleed, burn, EMP, curse), ammo regen
- **Tradeoffs:** some upgrades have downsides (e.g. homing rounds reduce fire rate, explosive rounds risk self-damage)

The gun's **visual appearance** mutates with upgrades AND adapts to the era — your shotgun-pistol becomes a bone-shotgun in Prehistoric, a golden khopesh-shotgun in Egypt, a sawed-off in the Wild West, and a plasma-spreader in the Future. Same upgrades, different skin.

### Era-themed upgrade pools

Each era's shop offers upgrades flavored by its setting. Players who revisit eras in a different order get a different build:

- **Prehistoric:** raw damage, bleed, charge attacks
- **Egypt:** cursed upgrades (lifesteal, HP-for-power sacrifice)
- **Wild West:** precision, crit chance, ricochet
- **Future:** energy/tech, chain lightning, shield-piercing
- **Present:** balanced, defensive (kevlar, dodge buffs)

## Economy

- Each era has its own **native currency**: bones, gold coins, dollars, credits, USD.
- At the time machine hub, conversion rates fluctuate — timing matters.
- Money is spent on:
  - **Permanent player upgrades** (HP, dodge i-frames, ammo capacity, starting hearts, reroll tokens)
  - **Gun upgrade slots** in the era shops
  - **Repairs/customization** of the time machine hub (unlocks new shop tiers, NPCs, cosmetics)
- **No disposable gear inventory.** The Chrono-Pistol is your only weapon. No "sell at the end of the run" busywork.

## The boss & the chase

**One antagonist, evolving forms.** The boss is a single character fleeing through time. As they pass through each era, they fuse with that era's power and reappear at the end of the floor in a new form for you to fight:

- **Prehistoric:** fused with a T-Rex / apex predator — heavy melee bruiser with charge attacks.
- **Ancient Egypt:** mummified pharaoh — summons scarab swarms, curses your gun mid-fight.
- **Wild West:** outlaw gunslinger — quick-draw duels, ricochet bullet patterns.
- **Future:** cybernetic — shielded, teleports, drone summons.
- **Corrupted Present (finale):** their true form, a fusion of all four era-powers.

Each form is mechanically distinct (different moveset, attack patterns, weak points) but it's clearly the same character — same voice, same banter, same goal. The chase is personal.

### Stolen upgrades

Each time you beat a mid-era form, the boss escapes and **steals one of your gun upgrades** as they go. They don't use it themselves yet — they're hoarding. In the **final fight**, the boss reassembles all four stolen upgrades into their own weapon and turns your own build against you.

This means:
- Each mid-era fight loses you one upgrade going into the next era (incentive to swap builds).
- The final boss's loadout is a horror-mirror of your specific run — every player's final fight is different.
- On defeat, each mid-era boss form also drops a unique era-themed upgrade card as compensation.

## Era-specific mechanics

| Era | Signature mechanics | Status effects | Hazards |
|---|---|---|---|
| **Prehistoric** | Charging dinos that stagger, swarm raptors, predator/prey AI | Bleed, fear aura | Tar pits, volcanic eruptions, falling trees |
| **Ancient Egypt** | Trap-heavy rooms (poison darts, spikes, crushing blocks), revivable mummies (destroy sarcophagus to stop respawn) | Curse (gun jams), sand-blinded | Sandstorms, scarab swarms, false floors |
| **Wild West** | Quick-draw duel rooms (reflex check), saloon brawls, bounty mini-bosses | Marked (next hit crits) | Tumbleweeds with bombs, runaway stagecoaches |
| **Future** | Shielded enemies needing specific damage types, drone swarms, gravity wells | Hacked (gun fires erratically), EMP'd | Energy fences, laser grids, lockdown rooms |
| **Present Day** | Police/SWAT, helicopter mini-bosses, civilian crowd management | Tased, mace'd | Cars, traffic, alarm systems |

## Time machine hub

Between eras, you return to a small overworld — the inside of the time machine. This is your shop, your upgrade space, and your social hub.

- **Workbench:** spend cash on permanent player upgrades.
- **Era selection console:** choose your next destination.
- **NPC roster:** unlock characters from each era who give passive run buffs (a tame raptor, a wandering sheriff, an alien mechanic).
- **Customization:** cockpit cosmetics, weapon skins, gameplay modifiers.

## Additional ideas worth exploring

These came up after the initial concept — keeping them here so they don't get lost.

1. **Time anomaly rooms.** Rare rooms where you encounter enemies from *other* eras (a T-Rex in Egypt, a cowboy in the Future). Unique loot. Easter-egg flavor.
2. **Time paradox mechanic.** Actions in one era subtly change another. Spare a scientist in the Present, get a tech discount in the Future. Save a pharaoh, Egypt's shop unlocks better stock. Encourages replay.
3. **Recurring enemy archetypes.** The "brute" archetype recurs across eras — caveman → sphinx guard → gunslinger → riot cop → mech. Mastering an archetype carries skill across the whole game.
4. **Hidden 6th era (NG+).** Unlock after beating the game once. Could be Atlantis, far-future apocalypse, or a true "outside time" void. Reveals the boss's true origin.
5. **Daily run / seeded leaderboard.** Gungeon does this. Cheap to add, big retention boost.
6. **Co-op mode.** Two players, each can pursue different eras and meet at boss fights. Probably v2 scope.
7. **Boss reveals through a "field journal".** The player character keeps a log that fills in lore as you progress. Doubles as a tutorial reference for status effects/enemies.
8. **Era-specific companion pets.** Each unlock-able after clearing that era — a baby raptor, a scarab swarm familiar, a robot dog, etc. Combat or utility role.
9. **Achievements tied to gun builds.** "Beat the game with a homing-shotgun build", "Beat the game with only explosive rounds", etc. Drives experimentation.
10. **Visual identity rule.** Every era should be recognizable at a one-frame glance by silhouette and color palette alone. If two screenshots from different eras look interchangeable, the art direction has failed.

## Tech stack

**Engine: Godot 4.x.** Solo-dev friendly, the developer already has experience with it, free + open source with no revenue royalties. Best-in-class 2D performance. Comparable shipped titles in Godot include Brotato, Halls of Torment, Cassette Beasts, and Dome Keeper. GDScript covers the bulk of the project; drop into C# only for performance hotspots (large bullet pools, AOE collision) if profiling demands it. Steam Deck export is trivial.

**Art style: stylized chunky pixel art, cartoony.** Reference look sits between Enter the Gungeon (bold outlines, expressive sprite work) and Brotato (exaggerated proportions, saturated palettes). Cult of the Lamb is another good cartoony pixel-art reference for mood.

Why pixel art over vector for this project:
- Solo-dev sustainable — frames-per-animation cost is bounded.
- The "one gun, multiple era skins" system is cheap with pixel art — recoloring and small silhouette tweaks instead of redrawing each era's variant from scratch.
- Reads "cartoony" without needing illustrator-grade hand-drawn assets.

### Tooling

| Purpose | Tool | Notes |
|---|---|---|
| Sprite art + animation | **Aseprite** | $20 one-time, industry standard for pixel art |
| Level layout | **LDtk** or **Tiled** | Both free, both have Godot importers |
| SFX | **ChipTone**, **sfxr/Bfxr** | Free, browser-based |
| Music | **BeepBox**, **LMMS** | Free; BeepBox for chiptune-leaning, LMMS for fuller tracks |
| Audio editing | **Audacity** | Free |
| Version control | **Git + GitHub** | Already in use (Creatition/high-voltage) |

## Open questions

- Player character name + backstory, or blank-slate avatar?
- Is the time machine itself a character (sentient AI, mysterious voice)?
- What's the boss's motivation — chaos, power, vengeance, accident?
- Pixel art resolution target: 32×32 sprites (Brotato chunky), 16×16 (Nuclear Throne tight), or 48×48 (Gungeon detailed)?

## Decisions locked in (2026-05-17)

- **Title:** Timeshot
- **Engine:** Godot 4.x
- **Art style:** stylized cartoony pixel art
- **Team:** solo dev
- **Boss design:** one antagonist, evolving era-fused forms, steals upgrades for final fight

---

*Living doc — last edited 2026-05-17.*
