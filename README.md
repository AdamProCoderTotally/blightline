# BLIGHTLINE

Godot **4.7.2** scaffold for a 3D tower defence game. Task Force Halcyon holds Firebase Halcyon at **Cinder Pass** against the Blighted. Gameplay numbers live in JSON so the design brief can be tuned without code changes.

This is the playable foundation: title screen, free overhead camera, free placement, a real wave list, and combat that reads the data. It is not the finished HUD, art, or every special ability.

## Run

Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/) (GDScript, not the .NET build). Open this folder and press F5, or:

```bash
godot --path . --rendering-method gl_compatibility
```

The game opens on the title screen. Sentinel is pre-selected. **Deploy** (or Enter) starts the match.

Headless checks:

```bash
godot --headless --path . --rendering-method gl_compatibility res://tools/smoke_test.tscn
```

`SMOKE PASS` means the data rules below loaded and behaved.

## Layout

| Path | Role |
|---|---|
| `scenes/title.tscn` | Mode select. Main scene. |
| `scenes/game.tscn` | The match. |
| `scripts/autoload/content_db.gd` | Loads JSON and builds the wave plan. |
| `scripts/autoload/game_state.gd` | Base HP, cash, income, leak, sell ratio. |
| `scripts/map/battlefield.gd` | Cinder Pass ground, road, blockers. |
| `scripts/map/placement_controller.gd` | Free placement and build hotkeys. |
| `scripts/towers/tower.gd` | Generic tower. Stats and upgrades from data. |
| `scripts/enemies/enemy.gd` | Generic enemy, shield, traits, boss attacks. |
| `scripts/enemies/wave_spawner.gd` | Prep, timed waves, skip, depot payout. |
| `scripts/camera/overhead_camera.gd` | Free overhead camera. No avatar. |
| `scripts/ui/hud.gd` | Mode, base HP, cash, wave, hotbar, upgrades. |
| `data/` | All tuning. |
| `tools/export_windows.sh` | Headless Windows export. |
| `tools/install_godot.sh` | Downloads Godot 4.7.2 and the Windows templates. |
| `docs/design-brief.md` | Design brief v1.1 (Cinder Pass) and acceptance criteria 1–52. |

## Data

JSON, not Godot resources. The brief's tables are plain numbers, and JSON can be edited and diffed without opening the editor. `export_presets.cfg` lists the files in `include_filter`, so they are packed into the Windows exe. `ContentDb` reads them at startup.

| File | Contents |
|---|---|
| `data/game_config.json` | Title, `$1` per HP, wave bonus `$75 + $25 × wave`, HP slope `0.05`, 20 s prep, 2 s group gap, leak mode, upgrade cap 3/2, camera limits. |
| `data/difficulties.json` | Recruit, Sentinel (default), Ironwall, Overrun. |
| `data/towers.json` | Picket Trooper, Lobber Team, Frostline Engineer, Arc Mast, Longshot, Supply Depot. Each has a base and two paths of five tiers. |
| `data/enemies.json` | Shambler, Sprinter, Plated Husk, Carrion Swarm, Hive Host, Stitcher, Sparkhead, Gristle, Mother Blight. |
| `data/waves.json` | 29 regular waves plus `boss_wave`. |
| `data/map_cinder_pass.json` | 64×40 m ground, 4 m road, the ten waypoints, blockers. |

A mode with N waves plays regular waves **1…N−1**, then the boss wave as wave **N**. Sentinel is 24, so waves 1–23 plus Mother Blight. `ContentDb.wave_count_error()` reports a clear error if N is larger than the list allows (30 with the current file).

Non-boss HP and shield scale by `(1 + 0.05 × (wave − 1)) × enemy_hp_mult`. Gristle and Mother Blight use `boss_hp_mult` only. Speed uses `enemy_speed_mult` for everyone. Leak damage is `ceil(remaining HP + remaining shield)` for every enemy, including bosses and no-cash spawns. Sell refund is `sell_ratio` (0.5) of cash spent. Damage to health pays `cash_per_hp × income_mult`; shield and overkill pay nothing.

Upgrade tiers are whatever length the path array has. The cross-path rule reads `upgrade_rules`: once one path reaches tier 3, the other cannot pass tier 2. Reachable tops are 5-2 and 2-5.

## Controls

- Right mouse: orbit. Pitch stays between 30° and 80°.
- WASD or arrows, middle mouse, or the screen edge: pan. Wheel: zoom 12–60 m. Home: reset.
- 1–6 or the hotbar: choose a tower. Left click places it. Hold Shift to place another. Q, or Esc, cancels. Esc with nothing selected pauses.
- Click a tower to select it. E / R upgrade top / bottom. Ctrl+E / Ctrl+R buy until the cap or the cash runs out. C / V change targeting. G uses Frag Toss or Overcharge when that tower has one. Backspace or Delete sells.
- Space skips the wave after its groups have spawned. F cycles 1x, 1.5x, 2x. P pauses. The camera and HUD keep running while paused.

## What the match already does

Towers fire from their base stats plus purchased deltas: burst, reload, splash, pierce, and chains. Resistances and ignore-resistance flags change the damage. Stealth and airborne enemies are not chosen as a primary target unless the tower has that detection; splash, pierce, and chains can still hit them. Hive Hosts split into four no-cash Sprinters. Stitchers heal. Sparkheads stun towers when they die. Gristle and Mother Blight attack towers only when the mode has tower HP (off on Recruit). Depots pay at the end of a wave they were not placed during, and top-path base healing cannot pass the mode's starting HP.

Still data-only, not simulated: the chill/freeze meter, incendiary patches, shatter and chill vulnerability, the full ability UI, line of sight, and the victory / defeat screens (the match sets a status line instead).

## Export a Windows exe

The preset **Windows Desktop** embeds the PCK in one exe (`binary_format/embed_pck=true`) and writes `build/windows/BLIGHTLINE.exe`.

In the editor: **Editor → Manage Export Templates** and install the 4.7.2 templates, then **Project → Export → Windows Desktop → Export Project**.

From a shell, after `tools/install_godot.sh` (or with `GODOT` pointing at a 4.7.2 binary and the templates in `~/.local/share/godot/export_templates/4.7.2.stable/`):

```bash
tools/export_windows.sh
```

The script checks that the output is a Windows executable, contains the PCK magic `GDPC`, and does not leave a sidecar `.pck`. A headless export of this preset was run with Godot 4.7.2 on Linux; the exe was not launched under Windows.
