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

Between eras, you return to a small overworld — the inside of the time machine. This is your shop, your upgrade space, your social hub, and the home of the game's narrator (see next section).

- **Workbench:** spend cash on permanent player upgrades.
- **Era selection console:** choose your next destination.
- **NPC roster:** unlock characters from each era who give passive run buffs (a tame raptor, a wandering sheriff, an alien mechanic).
- **Wardrobe:** swap between unlocked player characters/skins (see Character System below).
- **Customization:** cockpit cosmetics, weapon skins, gameplay modifiers.

## The narrating time machine

The time machine itself is a character — a sarcastic, world-weary AI voice that talks to you between rooms, comments on your build, narrates your boss fights, and slowly reveals lore over the course of the game. Cheap and high-leverage: text + a portrait/voice line carries enormous personality.

**References:** Hades (Zagreus's interactions with the house), Bastion (the narrator), Pyre (the Reader), Stanley Parable (the Narrator). Each used a talking presence to turn a mechanically simple framing into a memorable game.

The AI should:
- Comment on the player's gun build ("Going for a homing-explosive setup again? Bold.")
- React to which era the player picks next ("Egypt? Bring sunscreen.")
- Hint at the boss's motives across the game in a slow drip.
- Occasionally bicker with the player character (especially if the protagonist is named/voiced).
- Have a name. (TBD — open question.)

## Character system

The player can unlock and swap between multiple playable characters. Characters are **cosmetic at first, with potential for light gameplay variation** later (e.g., one character starts with +1 HP but -1 damage, another starts with a reroll token).

- All characters share the Chrono-Pistol upgrade system — no character-locked weapons.
- Unlock conditions: complete a full run with the previous character, beat specific bosses, find hidden NPCs, achieve specific milestones (clear an era without taking damage, etc.).
- Skins can be era-themed (a cavewoman, a pharaoh, a gunslinger, a cyborg) — naturally feeds the time-travel motif.
- Roster grows the game without bloating the systems work.

## Multiplayer roadmap

Two-phase approach. v1.0 ships with cooperative play that functions as online co-op via Steam's platform features. PvP is a post-launch addition.

### Phase 1 — v1.0 launch: solo + local co-op + Remote Play Together
- **Solo campaign:** full 5-era loop, gun system, narrator, character roster.
- **Local couch co-op:** 2–4 players, same screen, controllers. No netcode written.
- **Remote Play Together:** automatically enabled by Steam for local co-op games. Host runs the game, the host's screen is streamed to friends online, friend controller inputs are sent back. From the player's perspective this *is* online co-op.
  - Only the host needs to own the game — strong marketing angle.
  - Steam handles the streaming infrastructure. Zero work for the developer.
  - Works for 2–4 players. Quality is bound by host's upload bandwidth.
  - References that shipped with this approach as their "online co-op": Brotato, Cult of the Lamb, Streets of Rogue.

This means v1.0 has *functional* online co-op without me writing a single line of networking code. Cooperative latency is forgiving enough for Remote Play Together to feel native.

### Phase 2 — v1.x post-launch: Showdown PvP mode
A separate mode from the main menu. This phase introduces real networking because competitive PvP needs low, predictable latency that Remote Play Together cannot guarantee.

**Showdown — the Rounds-inspired PvP mode:**
- 2–4 players, small symmetric arenas (one map per era as the rotating pool).
- Last player standing wins the round.
- Best-of-X format for the match.
- **Rounds-style hook:** after each round, the player(s) who lost pick from 3 random gun upgrade cards. Winners get nothing. Built-in rubber-banding keeps matches close.
- Chrono-Pistol's upgrade system maps directly — same cards, same logic, different mode.
- Cosmetic character roster carries over from campaign.

**Networking stack for Showdown:**
- **GodotSteam** plugin (https://godotsteam.com/) wraps Steamworks SDK for Godot 4.
- Steam handles lobbies, matchmaking, friend invites, NAT punchthrough.
- P2P over Steam's relay network — no dedicated servers, no infrastructure cost.
- Godot 4's high-level MultiplayerAPI sits on top.
- Steam-only multiplayer is a fine trade for a solo dev; most indie multiplayer ships this way.

### Why this sequencing is the right call
- Local co-op + Remote Play Together = real online co-op on launch day, zero netcode debt.
- All netcode investment is concentrated in **one mode** (Showdown) where latency actually matters.
- Single-player and co-op share 95% of their code, so building one builds the other.
- PvP can ship as a free or paid update later, depending on launch reception.

### Possible future: true online co-op
If post-launch demand for "true" online co-op (drop-in/drop-out, no host machine required) is high, the GodotSteam stack built for Showdown can be extended to support it in v2.x. Defer the decision until launch data tells us if it's needed.

## Additional ideas worth exploring

These came up after the initial concept — keeping them here so they don't get lost.

1. **Time anomaly rooms.** Rare rooms where you encounter enemies from *other* eras (a T-Rex in Egypt, a cowboy in the Future). Unique loot. Easter-egg flavor.
2. **Time paradox mechanic.** Actions in one era subtly change another. Spare a scientist in the Present, get a tech discount in the Future. Save a pharaoh, Egypt's shop unlocks better stock. Encourages replay.
3. **Recurring enemy archetypes.** The "brute" archetype recurs across eras — caveman → sphinx guard → gunslinger → riot cop → mech. Mastering an archetype carries skill across the whole game.
4. **Hidden 6th era (NG+).** Unlock after beating the game once. Could be Atlantis, far-future apocalypse, or a true "outside time" void. Reveals the boss's true origin.
5. **Daily run / seeded leaderboard.** Gungeon does this. Cheap to add, big retention boost.
6. **Split-path co-op.** Two players pursue different eras simultaneously and meet at boss fights. Adds strategic choice but doubles design complexity — defer to a possible v2.x.
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

| Purpose | Tool | Link | Notes |
|---|---|---|---|
| Sprite art + animation | **Aseprite** | https://www.aseprite.org/ | $20 one-time, industry standard for pixel art |
| Level layout | **LDtk** | https://ldtk.io/ | Free, modern, made by Dead Cells dev — recommended |
| Level layout (alt) | **Tiled** | https://www.mapeditor.org/ | Free, more mature, also great |
| SFX | **ChipTone** | https://sfbgames.itch.io/chiptone | Free, browser-based, retro sfx |
| Music | **BeepBox** | https://www.beepbox.co/ | Free, browser-based chiptune composer |
| Audio editing | **Audacity** | https://www.audacityteam.org/ | Free, multi-platform |
| Multiplayer networking | **GodotSteam** | https://godotsteam.com/ | Steamworks wrapper for Godot — added in Phase 3 |
| Version control | **Git + GitHub** | https://github.com/Creatition/high-voltage | Already in use |

### Art specifications

- **Sprite resolution:** 32×32 base (player + enemies). Larger sprites for bosses (64×64 or 96×96). UI/HUD at native screen resolution.
- **Color depth:** limited palette per era (16–32 colors each) for consistency and stylization.
- **Animation framerate:** 8–12 fps for most actions, snappier (60 fps engine refresh, but discrete keyframes).

## Open questions

- What's the time machine AI's name and personality voice?
- Default starter character — does it have a name, or is the first character a blank-slate "Recruit"?
- What's the boss's motivation — chaos, power, vengeance, accident?
- Online co-op loot: shared pool or instanced per player?
- Music direction — chiptune, synth-orchestral hybrid (Hades-style), or era-distinct genres (saloon piano in West, synthwave in Future, etc.)?

## Decisions locked in

**2026-05-17:**

- **Title:** Timeshot
- **Engine:** Godot 4.x
- **Art style:** stylized cartoony pixel art
- **Sprite resolution:** 32×32 base (larger for bosses)
- **Team:** solo dev
- **Boss design:** one antagonist with evolving era-fused forms; steals upgrades for final fight
- **Narrator:** sarcastic AI voice of the time machine (Hades/Bastion-style)
- **Character system:** unlockable swappable characters/skins, all sharing the Chrono-Pistol system
- **Multiplayer roadmap:** v1.0 ships with solo + local couch co-op + Steam Remote Play Together (acts as online co-op). v1.x post-launch adds **Showdown** (PvP Rounds-style mode) with real netcode via GodotSteam.
- **Time paradox mechanic:** confirmed, actions in one era ripple into others

---

*Living doc — last edited 2026-05-17.*
