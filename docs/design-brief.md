# BLIGHTLINE: Game Design Brief (MVP)

*Owner: TD Researcher. Builder: TD Coder. Checker: TD Reviewer.*
*Version 1.1, 16 Nov 2026 (approved by Adamas with changes)*

## Changelog
**v1.1 (16 Nov 2026)**
- **Re-theme (military vs zombies, all names original):**
  - Title: *SCRAPLINE* → **BLIGHTLINE**. You command **Task Force Halcyon** at **Firebase Halcyon** against **the Blighted**. The map is now **Cinder Pass**.
  - Towers: Picket Trooper, Lobber Team, **Frostline Engineer** (was Frostcaster), Arc Mast, Longshot, **Supply Depot** (was Supply Pad).
  - Enemies: **Shambler, Sprinter, Plated Husk, Carrion Swarm, Hive Host, Stitcher, Sparkhead**. Mini-boss **Gristle**. Final boss **Mother Blight**.
- **Leak rule made explicit (§2.1):** a leaking enemy deals base damage equal to its **remaining HP + remaining shield**, rounded up. There is no fixed leak value and no special "boss destroys base" rule; bosses follow the same formula.
- **Base HP and bosses rebalanced:**
  - Default base HP **300 → 500**.
  - Mother Blight **9,000+3,000 → 30,000 HP + 10,000 shield** (default mode).
  - Gristle (mini-boss) stays at 2,500+500 and now also appears on wave 22 (×2).
  - Both bosses scale per mode with a boss HP multiplier.
- **Difficulty modes added (§6.5, `difficulties.json`):**
  - **Recruit** (16 waves)
  - **Sentinel** (24 waves, default)
  - **Ironwall** (30 waves)
  - **Overrun** (30 waves, optional 4th)
  - Picked on the title screen. The final boss is always the last wave.
- **Default mode is now 24 waves** (TDX Easy length). The master wave list was extended to 29 regular waves plus one boss wave.
- **5 upgrade tiers per path** (60 upgrades total), using TDX's cap rule: once one path reaches tier 3, the other path is capped at tier 2, so the maximums are `5-2` and `2-5`. Every path gained a tier-5 upgrade, and cash targets and boss HP were resized to match.
- **HUD/UI:** title screen with mode select; mode badge in the HUD; tier pips 0–5.
- **Acceptance criteria:** renumbered **1–52**. AC 41–52 cover leaks, modes and tier 5.
- **Open questions:** all 8 resolved (camera: free overhead camera; tower HP: only bosses damage towers; 5 tiers; 50% sell refund; military/zombie theme; 24-wave default). Removed from the list.

**v1.0 (16 Nov 2026):** first brief.

---

> **Feel target:** play and feel as close as possible to Roblox's **Tower Defense X (TDX)**:
> - free placement anywhere on buildable ground
> - **two upgrade paths with 5 tiers each**, where committing deeply to one path caps the other
> - **damage types with % resistances**
> - enemies that can be **stealthed** or **airborne**
> - **shield** HP that pays no cash
> - cash earned **per point of damage dealt**, plus a cash bonus at wave start
> - **timed waves** you can skip
> - **difficulty modes** chosen before the match
> - a big **base-health** pool that leaks drain by the leaker's remaining HP
> - **bosses that attack and stun towers**, so cheap "bait" towers matter
> - TDX-style hotkeys (1–6, Q, E/R, C/V, G, Backspace)
> - a short radio tip from an advisor each wave
>
> **Originality rule:** every name, model, icon, line of text and sound in this game is ours. None of TDX's (or any other game's) tower, enemy, boss, faction or character names, lore, art, audio or UI art may be used. We copy *mechanics and numbers-in-spirit* only. The research appendix names other games purely as citations.

---

## 1. Pitch, theme, platform, core loop

**Pitch.** A 3D single-player tower defence game. A fungal plague called **the Blight** has turned the valley's population into shambling **Blighted**. **Task Force Halcyon** holds **Firebase Halcyon**, the last fuel-and-evacuation point at the top of **Cinder Pass**. Deploy troopers, rocket crews, engineers and snipers anywhere off the road. Pick one of two upgrade paths for each of them, balance detection (stealth and air) against resistances, and hold out until **Mother Blight**, a towering hive-queen that spits bile at your towers, comes up the pass on the final wave.

**Tone.** Light, slightly comedic military-versus-zombies with a 1980s action-movie feel. Stylised chunky low-poly models: olive/khaki soldiers with teal unit markings, and sickly green/purple Blighted with glowing fungal growths. **No gore:** defeated Blighted burst into harmless green spore puffs.

**Platform.** Windows 10/11 x64, built as a standalone `.exe` with the Godot 4.x export templates. Mouse and keyboard. Target 60 FPS at 1080p on integrated graphics, with up to 200 enemies and 40 towers on screen.

**Engine.** Godot 4.x (latest stable 4.x), GDScript only, Forward+ or Mobile renderer (the coder chooses; Mobile is safer on iGPUs).

**Core loop** (one match ≈ 15 min on Recruit, ≈ 25–30 min on Sentinel, ≈ 35–40 min on Ironwall/Overrun):
1. On the title screen, choose a **difficulty mode** (§6.5). This sets the wave count, multipliers, cash and base HP.
2. Prep timer (wave 0). Place your first towers.
3. The wave spawns. Towers fire automatically. **Every point of HP damage pays cash**, and each wave start pays a bonus.
4. Spend mid-wave: place towers, upgrade the top path (E) or bottom path (R), switch targeting (C/V), fire abilities (G), sell (Backspace).
5. Read the next threat from the radio tip and the next-wave preview, and get the right detection or damage type in place.
6. The timer runs out (or you press Skip) and the next wave starts, even if enemies remain.
7. Win by beating the mode's final wave (Mother Blight). Lose when base HP reaches 0.

---

## 2. MVP map: "Cinder Pass"

**Ground.** A flat 64 m × 40 m play area (1 Godot unit = 1 m). It is a scorched mountain road with burnt-out trucks, sandbags and pine stumps as decoration, and rock walls at the edges. World X runs 0→64 (left→right) and Z runs 0→40 (top→bottom).

**Path.** One ground road, **4 m wide**, defined as a `Path3D`/`Curve3D` polyline. Enemies follow the centreline with a small random lateral offset (±0.6 m) so they don't stack. Waypoints (x, z):

| # | Point | Note |
|---|---|---|
| 0 | (0, 8) | **Spawn**: a collapsed tunnel mouth oozing Blight on the left edge |
| 1 | (14, 8) | |
| 2 | (14, 32) | long south run |
| 3 | (30, 32) | |
| 4 | (30, 10) | long north run |
| 5 | (46, 10) | |
| 6 | (46, 30) | |
| 7 | (58, 30) | |
| 8 | (58, 20) | |
| 9 | (64, 20) | **Base**: Firebase Halcyon's gate and fuel depot on the right edge |

Total length is **≈140 m**. A Shambler (2.8 m/s) takes ≈50 s to walk it. The serpentine layout gives three "inside bends" (around x 14–30, 30–46 and 46–58) where one tower covers two lanes. These are the intended power spots, as on TDX maps.

ASCII overview (1 char ≈ 2 m, `#` road, `.` buildable, `x` blocker such as a wreck or rocks, `S` spawn, `B` base):

```
      x0        x20       x40       x60
 z0   .................................
 z2   .................................
 z4   .....x...........................
 z6   ...............................x.
 z8   S#######............x............
 z10  .......#.......#########.........
 z12  .......#.......#.......#.........
 z14  .......#.......#.......#.........
 z16  .......#.......#.....x.#.........
 z18  .......#.......#.......#.........
 z20  ...x...#.......#.......#.....###B
 z22  .......#.......#.......#.....#...
 z24  .......#..xx...#.......#..x..#...
 z26  .......#.......#.......#.....#...
 z28  .......#.......#...x...#.....#...
 z30  .......#.......#.......#######...
 z32  .......#########.................
 z34  .................................
 z36  ....x............................
 z38  ..........................x......
 z40  .................................
```

**Air lane.** Airborne enemies follow the same curve at a height of 4 m.

**Buildable rules (free placement, TDX-style, no grid):**
- Each tower has a circular **footprint radius** (see the tower data). The placement ghost is valid only if the footprint is (a) entirely on the `buildable` ground area, (b) at least `path_half_width (2 m) + footprint` from the road centreline, (c) not overlapping any other tower's footprint or a blocker (2–3 m colliders), and (d) inside the map bounds.
- The ghost shows the model, a **range ring**, and a green (valid) or red (invalid) tint. The placement cost appears next to the cursor.
- **Supply Depot** has a placement limit of 6. All other towers are unlimited.
- *(Post-MVP: line of sight and raised ground. See §12.)*

### 2.1 Base HP and the leak rule (explicit)
- The firebase has a **base HP pool set by the mode**: Recruit 800 / **Sentinel 500** / Ironwall 400 / Overrun 300.
- **Leak damage = ceil(remaining HP + remaining shield)** of the enemy *at the moment it reaches the gate*. Then the enemy is removed. There is **no fixed leak value, no minimum, and no special boss rule**: bosses use the same formula.
- **Shield counts.** It is part of what got through, it is already visible on the health bar, and counting it keeps the rule to one number the player can read. (Shield still pays no cash.)
- Enemies spawned by other enemies (no-cash spawns) leak by the same rule.
- Base HP can be restored by the Supply Depot's top path, but **never above the mode's starting base HP**.
- At 0 base HP, the match is lost immediately (Defeat screen).

**Why base HP 500 on Sentinel (was 300).** The biggest single non-boss enemy on the last regular wave (23) is an untouched Hive Host at 150 × hp_mult(23) = 150 × 2.10 = **315**. With 300 base HP, one full-health Hive Host leak late in the game would end the run. That is too punishing for the default mode. With 500, the worst single leak, still at full health, costs 63% of the base: survivable once, but two big leaks are a loss. Typical "small leaks" barely register: a damaged Plated Husk at half HP costs ~84 and a Sprinter costs ≤ 18.

**Why a boss leak is still a loss.** On Sentinel, Mother Blight has 40,000 effective HP, which is **80× base HP**. She only survives a leak if she reaches the gate with **< 1.25%** (under 500) of her HP left. On Sentinel, Gristle (3,000 effective) is **6× base HP**. His leak is survivable only below 16.7% HP (500 of 3,000), so letting him walk through is a loss or very close to one. The per-mode numbers are in §6.5.

---

## 3. Camera and controls (mouse + keyboard), confirmed: free overhead camera, no avatar

**Camera rig:** a pivot node on the ground plane → a yaw node → a pitch node → `Camera3D` at distance *d*.
- **Orbit:** hold **Right Mouse** and drag. Yaw is unlimited. Pitch is clamped to 30°–80° below horizontal.
- **Pan:** **W A S D** / arrow keys (relative to camera yaw, 25 m/s, scaled by zoom), or hold **Middle Mouse** and drag. The pivot is clamped to the map bounds +5 m.
- **Zoom:** **mouse wheel**, distance 12–60 m with smooth lerp. Default is 40 m at 55° pitch, centred on the map.
- **Reset camera:** **Home**.
- Camera movement uses unscaled delta, so it is unaffected by game speed or pause.

**Input map (TDX layout where it applies):**

| Action | Key / mouse | Notes |
|---|---|---|
| Select tower to place | **1–6** or click hotbar slot | Opens the placement ghost |
| Place tower | **Left click** | Holding **Shift** keeps the same tower selected for repeat placement |
| Cancel placement / deselect | **Q** or **Esc** (Esc opens pause if nothing is selected) | |
| Select a placed tower | **Left click** it | Opens the tower panel and shows its range ring |
| Upgrade **top** path | **E** | |
| Upgrade **bottom** path | **R** | |
| Max-upgrade top / bottom | **Ctrl+E / Ctrl+R** | Buys tiers in order while affordable and allowed by the cap |
| Cycle targeting left / right | **C / V** | |
| Use tower ability | **G** | Only when the selected tower has one |
| Sell selected tower | **Backspace** (also **Delete**) | No confirmation for MVP |
| Skip wave / start now | **Space** or HUD button | Shown when skip is allowed (§6.1) |
| Game speed cycle | **F** or HUD button | 1x → 1.5x → 2x → 1x |
| Pause | **P** / **Esc** / HUD button | Camera moves, selecting, upgrading and selling all still work while paused |
| Toggle all range rings | **T** | |

All bindings live in the `InputMap` so they can be remapped later.

---

## 4. Towers (6 for MVP), 5 tiers per path

### 4.1 Shared rules
- **Two upgrade paths per tower, Top and Bottom, with 5 tiers each.** A tower's level reads `top-bottom`, e.g. `3-1`. **Cross-path cap (TDX rule):** once one path reaches **tier 3 or more**, the other path is capped at **tier 2**. Reachable maximums are therefore **`5-2` and `2-5`**. `3-3` is impossible. Tiers in a path must be bought in order. 6 towers × 2 paths × 5 tiers = **60 upgrades**.
- **Upgrade effects are additive deltas** on the base stats. Flags (stealth detection, air targeting, ignore-resistance, abilities) are OR-ed. "Replaces" entries (e.g. ability level 2) override earlier values. Because deltas commute, a `2-2` tower = base + top T1–T2 + bottom T1–T2.
- **Damage types:** `kinetic`, `blast`, `arc`, `frost`. Enemies have % resistance per type (0–90%). An "ignore X resistance" flag deals full damage of type X.
- **Detection:** by default towers hit **ground, non-stealth** enemies only. `stealth_detection` and `air_targeting` come from base stats or upgrades. Splash, chain and pierce damage **can still hit** stealth/air enemies indirectly, but cannot pick them as the primary target.
- **Targeting modes** (C/V cycles them; default **First**): **First**, **Last**, **Strongest** (highest current HP + shield), **Weakest**, **Closest**. Supply Depot has no targeting.
- **Tower HP** (confirmed): every tower has HP, shown when hovered or selected. **Only bosses (Gristle, Mother Blight) damage towers.** Each tier adds +25% of base HP (tier 5 = +125% in that path). A tower at 0 HP is destroyed with no refund. Towers regain 10% of max HP at every wave start. Tower HP is disabled in Recruit mode (§6.5).
- **Stun:** a stunned tower stops attacking and its ability is disabled for the stun's duration.
- **Sell refund: 50%** of total cash spent on the tower (confirmed). This comes from the mode's `sell_ratio`, which is 0.5 in every mode.
- **DPS** below = damage × shots ÷ cycle time against an unresisted target, for tuning reference.

### 4.2 Tower roster (summary)

| # | Tower | Role | Cost | Dmg type | Hits air | Stealth | Max path cost (top / bottom) |
|---|---|---|---|---|---|---|---|
| 1 | **Picket Trooper** | cheap starter rifleman, burst fire, bait | $250 | kinetic | no | Top T3 | $10,750 / $10,550 |
| 2 | **Lobber Team** | two-soldier rocket crew, splash | $600 | blast | Top T4 | Top T3 | $14,850 / $16,050 |
| 3 | **Frostline Engineer** | cryo-sprayer, slow → freeze support | $300 | frost | Bottom T4 | Bottom T3 | $11,900 / $12,150 |
| 4 | **Arc Mast** | field-engineered tesla pylon, chain lightning, anti-air | $700 | arc | **yes** | Bottom T3 | $15,600 / $17,950 |
| 5 | **Longshot** | sniper nest, very long range, anti-boss | $500 | kinetic | **yes** | Top T2 | $15,750 / $13,850 |
| 6 | **Supply Depot** | economy: a supply truck pays out every wave | $400 | – | – | – | $21,300 / $18,600 |

### 4.3 Tower details (T1–T4 unchanged from v1.0; **T5 is new**)

#### 1. Picket Trooper: starter rifleman
Base: **$250**, HP 100, footprint 1.2 m. Kinetic **burst of 3 × 2 dmg** (0.12 s between shots), reload 1.5 s, range 10 m. Ground only. DPS ≈ 3.4.

| Path | Tier | Name | Cost | Effect (delta) | Result / DPS |
|---|---|---|---|---|---|
| Top: *Marksman* | 1 | Scope Rail | 150 | range +3 | range 13 |
| | 2 | Drill Sergeant | 350 | dmg +1, reload −0.2 | 3 dmg, 1.3 s |
| | 3 | Thermal Visor | 800 | **stealth detection**, burst +2, reload −0.3 | 5×3, 1.0 s ≈ 10 |
| | 4 | Heavy Rounds | 2,200 | dmg +5, range +2 | 5×8, 15 m ≈ 27 |
| | **5** | **Squad Automatic** | **7,000** | **full-auto: no bursts, one shot every 0.15 s**; dmg +6; range +3 | 14 dmg / 0.15 s ≈ **93**, 18 m |
| Bottom: *Assault* | 1 | Hardened Tips | 200 | dmg +1.5 | 3.5 dmg |
| | 2 | Quick Mag | 400 | reload −0.3, range +2 | 1.2 s, 12 m |
| | 3 | Breacher Kit | 1,200 | **ignore kinetic resistance**, dmg +2, burst +1 | 4×5.5 ≈ 14 |
| | 4 | Frag Pack | 2,000 | burst +2, **Ability: Frag Toss I** | 6×5.5 ≈ 18 + ability |
| | **5** | **Demolition Kit** | **6,500** | dmg +5, burst +1; ability → **Frag Toss II**; passive **Incendiary Round** every 8 s | 7×10.5 ≈ **38** + ability + fire |

*Frag Toss I (G):* 80 blast damage, 3 m splash, 10 s cooldown. *Frag Toss II:* 140 blast, 4 m splash, 6 s cooldown. *Incendiary Round:* leaves a 3 m fire patch on the path that does 6 blast DPS for 4 s.

#### 2. Lobber Team: rocket crew
Base: **$600**, HP 120, footprint 1.5 m. **Blast 30 dmg**, splash 2.5 m, reload 4.0 s, range 18 m, arcing rocket (≈20 m/s). Ground only. DPS 7.5 per target hit.

| Path | Tier | Name | Cost | Effect | Result |
|---|---|---|---|---|---|
| Top: *Precision* | 1 | Dense Warheads | 500 | dmg +25 | 55 |
| | 2 | Rangefinder | 250 | range +5 | 23 m |
| | 3 | Seeker Optics | 1,500 | **stealth detection**, dmg +25, reload −0.5 | 80 / 3.5 s |
| | 4 | Skypiercer | 3,000 | **air targeting**, dmg +60, range +6 | 140 / 3.5 s, 29 m ≈ 40 |
| | **5** | **Bunker Buster** | **9,000** | dmg +120, reload −1.0, **primary target takes ×1.5** (splash victims ×1) | 260 (390 primary) / 2.5 s ≈ **156** single |
| Bottom: *Barrage* | 1 | Fast Loader | 200 | reload −1.0 | 3.0 s |
| | 2 | Twin Tubes | 250 | reload −1.0 | 2.0 s ≈ 15 |
| | 3 | Shaped Charge | 1,800 | **ignore blast resistance**, splash +1.5, dmg +20 | 50, 4 m |
| | 4 | Salvo Rack | 3,200 | **3 rockets per volley**, each full damage, landing within 2 m of the target | ≈ 75 area |
| | **5** | **Rocket Battery** | **10,000** | **5 rockets per volley**, dmg −10, reload −0.6, **stealth detection** | 5×40 / 1.4 s ≈ **143** area |

#### 3. Frostline Engineer: cryo support
Base: **$300**, HP 60, footprint 1.2 m. A cryo-sprayer applies **6 chill** per hit to up to **3 targets** (1 m splash), reload 0.3 s, range 8 m. **0 damage** until tier 3. Ground only.

**Chill model** (simplified from TDX's freeze meter): each enemy has `chill_capacity`. Chill builds up per hit, reduced by frost resistance. **Slow = 50% × chill / capacity.** At full chill the enemy is **frozen** (speed 0) for 1.5 s, then chill resets to 0 with 1 s of freeze immunity. Chill decays at 30% of capacity per second once the enemy has gone 0.5 s without a hit. **Bosses never freeze** (except via Cryo Lance T4–T5), and their slow is capped at 30%.

| Path | Tier | Name | Cost | Effect | Result |
|---|---|---|---|---|---|
| Top: *Blizzard* | 1 | Colder Coils | 250 | chill +2 | 8 |
| | 2 | Wide Nozzle | 250 | range +2.5 | 10.5 m |
| | 3 | Ice Storm | 1,000 | 2 frost dmg/hit, targets +2, chill +3 | 5 targets, 11 chill |
| | 4 | Shatterpoint | 2,600 | **frozen enemies take +40% damage from all sources**, targets +2, splash +1 | 7 targets |
| | **5** | **Whiteout** | **7,500** | chill +6, targets +5, dmg +4, freeze lasts **2.5 s**, **ignores frost resistance** | 12 targets, 6 dmg/hit (≈ 20 DPS each) |
| Bottom: *Cryo Lance* | 1 | Focus Lens | 400 | chill +4, targets −2 (single target) | 10 chill |
| | 2 | Turbo Pump | 450 | reload −0.05, range +2 | 0.25 s, 10 m |
| | 3 | Lance Core | 1,500 | 6 frost dmg/hit, **stealth detection** | 24 DPS |
| | 4 | Absolute Zero | 3,000 | **air targeting**, dmg +6; boss slow cap → 60%; can freeze a boss for 1 s (once per 15 s per boss) | 48 DPS |
| | **5** | **Cryo Spike** | **6,500** | dmg +12; boss freeze → **1.5 s, once per 12 s**; the target takes +25% damage from all sources while chilled ≥ 50% | **96** DPS |

#### 4. Arc Mast: tesla pylon
Base: **$700**, HP 90, footprint 1.4 m. **Arc 10 dmg**, chains to **2 extra** enemies within 4 m of the previous one (each jump ×0.7 damage), reload 1.2 s, range 11 m, instant. **Hits air.** No stealth detection (chains can still jump onto stealthed enemies).

| Path | Tier | Name | Cost | Effect | Result |
|---|---|---|---|---|---|
| Top: *Storm* | 1 | Extra Coil | 300 | chains +1 | 3 jumps |
| | 2 | Capacitor Bank | 500 | reload −0.2 | 1.0 s |
| | 3 | Tempest Crown | 1,600 | chains +2, dmg +6 | 16, 5 jumps |
| | 4 | Overcharger | 3,500 | dmg +8, **Ability: Overcharge** (reload halved for 6 s, 30 s cooldown) | 24 dmg |
| | **5** | **Thunderhead** | **9,000** | dmg +16, chains +3, jump falloff ×0.7 → **×0.85**; Overcharge cooldown → 20 s | 40 dmg, 8 jumps |
| Bottom: *Focus Beam* | 1 | Narrow Gap | 350 | dmg +6, chains −1 | 16, 1 jump |
| | 2 | Tall Mast | 600 | range +3 | 14 m |
| | 3 | Beam Emitter | 1,800 | **stealth detection**, dmg +14, chains −1 (single target), reload −0.6 | 30 / 0.6 s = 50 |
| | 4 | Plasma Lance | 4,000 | dmg +15 | 45 / 0.6 s = 75 |
| | **5** | **Sunspear** | **10,500** | dmg +55, reload −0.1, range +2 | 100 / 0.5 s = **200** single |

#### 5. Longshot: sniper nest
Base: **$500**, HP 80, footprint 1.2 m. **Kinetic 25 dmg** hitscan, reload 2.5 s, range 26 m. **Hits air.** DPS 10.

| Path | Tier | Name | Cost | Effect | Result |
|---|---|---|---|---|---|
| Top: *Eagle Eye* | 1 | Match Ammo | 250 | dmg +10 | 35 |
| | 2 | Night Optics | 500 | **stealth detection**, range +4 | 30 m |
| | 3 | Anti-Materiel | 1,500 | dmg +40, reload −0.3 | 75 / 2.2 s |
| | 4 | Railbolt | 3,500 | dmg +80, reload −0.4 | 155 / 1.8 s ≈ 86 |
| | **5** | **Widowmaker Rig** | **9,500** | dmg +245, reload −0.2, **ignore kinetic resistance** | 400 / 1.6 s = **250** single |
| Bottom: *Suppressor* | 1 | Bolt Polish | 300 | reload −0.5 | 2.0 s |
| | 2 | AP Core | 450 | ignores **50%** of kinetic resistance | |
| | 3 | Overpenetrator | 1,600 | **pierce 3**, **full ignore kinetic resistance**, dmg +15 | 40 |
| | 4 | Concussive Rounds | 3,000 | dmg +20, reload −0.7, hits **stun non-boss enemies for 0.5 s** | 60 / 1.3 s ≈ 46 |
| | **5** | **Overwatch Team** | **8,000** | dmg +10, reload −0.5, pierce +2 | 70 / 0.8 s ≈ **87** × up to 5 targets |

#### 6. Supply Depot: economy (TDX-style farm)
Base: **$400**, HP 150, footprint 2.0 m, **limit 6**. When each wave ends (on Skip or when its timer reaches 0), a supply truck drives up to the depot and pays **$100**. A depot placed mid-wave pays from the next wave end. Upgrades take effect at the next payout. Payouts are multiplied by the mode's `income_mult`.

| Path | Tier | Name | Cost | Effect | Payout / wave |
|---|---|---|---|---|---|
| Top: *Field Depot* | 1 | Fast Convoy | 100 | +$20 | 120 |
| | 2 | Repair Bay | 300 | towers within 8 m regain +15% max HP each wave | 120 |
| | 3 | Med Supplies | 2,500 | +$150; **restores 5 base HP** per wave (capped at the mode's starting base HP) | 270 |
| | 4 | Strategic Reserve | 6,000 | +$300; base restore +10 (15 total) | 570 |
| | **5** | **Forward Operating Base** | **12,000** | +$800; base restore +10 (25 total); Repair Bay radius 12 m | **1,370** |
| Bottom: *Logistics* | 1 | Bigger Crates | 700 | +$150 | 250 |
| | 2 | Bulk Orders | 1,200 | +$250 | 500 |
| | 3 | Priority Freight | 1,800 | +$350 | 850 |
| | 4 | Double Run | 3,500 | +$550 | 1,400 |
| | **5** | **Convoy Contract** | **11,000** | +$600 | **2,000** |

Depots pay for themselves in about 4–6 waves up to tier 4, and tier 5 takes about 8–18 waves. Tier 5 is a deliberate late-game greed or sustain pick, as with TDX farms.

---

## 5. Enemies: the Blighted (8 types incl. boss) + mini-boss

**Shared rules**
- **HP** (cash-paying) plus an optional **Shield** layer that is damaged first and **pays no cash**. The health bar shows shield as a blue segment.
- **Stealth is a modifier any enemy can carry.** Wave entries set `stealth: true`. Stealth enemies render at 35% alpha with a "camo" striped health bar and an eye-slash icon.
- **Airborne:** hover at 4 m. Only `air_targeting` towers can target them.
- **No-cash spawns:** enemies spawned by other enemies pay $0 and inherit the parent's stealth flag.
- **Leak:** see §2.1 (remaining HP + remaining shield).
- **HP scaling:** non-boss HP and shield × `hp_mult(w) = (1 + 0.05 × (w − 1)) × mode.enemy_hp_mult`. Bosses (Gristle, Mother Blight) use fixed base values × `mode.boss_hp_mult` and ignore `hp_mult(w)`.
- **Speed** (m/s) × `mode.enemy_speed_mult` (applies to bosses too).

| Enemy | HP | Shield | Speed | Resist (kin/blast/arc/frost) | Chill cap | Traits |
|---|---|---|---|---|---|---|
| **Shambler** (basic) | 10 | – | 2.8 | – | 20 | none |
| **Sprinter** (fast) | 8 | – | 6.0 | – | 15 | very fast, fragile |
| **Plated Husk** (armoured) | 60 | 20 | 1.8 | **40** / – / – / – | 60 | wears scavenged riot plate; resists kinetic |
| **Carrion Swarm** (air) | 30 | – | 3.5 | – | 25 | **airborne**: a cloud of infected crows |
| **Hive Host** (splitter) | 150 | – | 2.0 | – / 25 / – / – | 80 | bloated carrier; on death bursts into **4 Sprinters** (no cash) |
| **Stitcher** (healer) | 120 | – | 2.4 | – / – / 25 / 50 | 60 | every 3 s heals allies within 6 m for 8% of their max HP (max 150 per target, never itself) |
| **Sparkhead** (stunner) | 90 | – | 3.0 | – / 30 / – / – | 50 | ex-lineman tangled in live cable; on death, an EMP **stuns towers within 6 m for 2.5 s** |
| **Mother Blight** (final boss) | **30,000** | **10,000** | 1.4 | 25 / 25 / – / 50 | 4,000 (never freezes) | see below |

**Mother Blight: final boss (last wave of every mode).** A three-storey fungal hive-queen dragging a cocoon sac. She has a boss health bar at the top of the screen and is stun-immune. Base stats above are for Sentinel; multiply by `boss_hp_mult`.
- *Bile Mortar:* every 6 s, lobs bile at the **most expensive tower within 20 m**: 60 damage to that tower. Ties go to the most recently placed tower.
- *Quake Stomp:* every 12 s, **stuns all towers within 8 m for 2 s**.
- *Brood Call:* every 20 s, drops **4 Shamblers** (no cash) at her feet.
- *Frenzy:* below 30% HP, speed +25% and Bile Mortar interval 4 s.
- **Leak:** her remaining HP + shield, per §2.1. On Sentinel she must be under 500 effective HP (≤ 1.25%) to survive a leak, so in practice a leak is a loss.

**Gristle: mini-boss (waves 10 and 22; ×3 on wave 27 in long modes).** A hulking Blighted brute in a burst army flak vest, 1.5× human scale. **HP 2,500 + shield 500** (× `boss_hp_mult`), speed 1.6, resist 25 / 25 / – / 50, chill cap 600 (never freezes). Ability: *Rubble Throw*, which hits the **closest** tower within 16 m for 40 damage every 7 s. It teaches tower HP and baiting before the finale. **Leak:** remaining HP + shield. On Sentinel that is 3,000 = 6× base, so it is survivable only if he is below 16.7% HP.

**Boss sizing reasoning (Sentinel).**
- A player entering wave 24 has earned ≈ $68k in total (§6.3), enough for roughly two tier-5 towers plus three or four tier-3/4 towers.
- Mother Blight walks ≈140 m at 1.4 m/s, which is about 100 s of exposure before slows. Each tower covers only part of that path.
- 40,000 effective HP at 25% kinetic/blast resistance therefore needs about **400–500 sustained effective DPS across the path**. That is achievable with a committed tier-5 build and lethal for an under-built defence.
- The old 12,000 HP boss would have melted in under 30 s once tier 5 existed.

---

## 6. Waves and difficulty modes

### 6.1 Structure (TDX-style timed waves)
- **Wave 0** is a 20 s prep timer. Then waves 1…N run, where **N = the mode's `wave_count`**.
- Each wave has a **timer**. When it reaches 0, the next wave starts **even if enemies remain**. The **Skip button / Space** appears once all of the current wave's enemies have spawned. Pressing it starts the next wave immediately. There is **no skip bonus** (`skip_bonus_per_sec` = 0).
- **Wave-start cash bonus** = `(75 + 25 × wave) × mode.income_mult`.
- Groups spawn in the listed order. Each group spawns its count at the listed spacing, with a 2 s gap between groups.
- **Radio tip:** one short line from **Sgt. Okafor** (our advisor) per wave, shown for 8 s (§6.4).
- **Win:** the mode's final wave (Mother Blight) is cleared, all enemies are dead, and base HP > 0. Shows the **Victory** screen.
- **Lose:** base HP ≤ 0 at any point. Shows the **Defeat** screen. There is no separate boss-leak rule; a boss leak is a loss because of its HP (§2.1).

### 6.2 Master wave list
`waves.json` holds **29 regular waves** plus **one `boss_wave` template**. A mode with N waves plays **regular waves 1…N−1, then the boss wave as wave N** (§6.5). `(S)` = stealth variant. "Eff. HP" = HP + shield after `hp_mult(w)` on **Sentinel** (×1.0), including spawned Sprinters. Gristle counts at 3,000 each.

| Wave | Timer | Composition (in order) | Spacing | New threat | Eff. HP |
|---|---|---|---|---|---|
| 1 | 45 s | 6 Shambler | 1.5 | – | 60 |
| 2 | 45 s | 12 Shambler | 1.0 | – | 130 |
| 3 | 45 s | 8 Sprinter, 8 Shambler | 0.8 | fast | 160 |
| 4 | 45 s | 14 Sprinter, 10 Shambler | 0.7 | | 240 |
| 5 | 50 s | 4 Plated Husk, 12 Shambler | 1.0 | armour + shield | 530 |
| 6 | 50 s | 12 Plated Husk, 10 Sprinter | 0.9 | | 1,300 |
| 7 | 50 s | 6 Carrion Swarm, 15 Shambler | 0.9 | **air** | 430 |
| 8 | 50 s | 10 Sprinter (S), 10 Plated Husk | 0.8 | **stealth** | 1,190 |
| 9 | 55 s | 3 Hive Host, 12 Carrion Swarm | 1.2 | splitter | 1,270 |
| 10 | 90 s | 20 Plated Husk, then **Gristle** | 0.8 | **mini-boss, tower damage** | 5,320 |
| 11 | 55 s | 3 Stitcher, 15 Plated Husk | 0.9 | healer | 2,340 |
| 12 | 55 s | 20 Sprinter, 4 Sparkhead | 0.7 | stunner | 810 |
| 13 | 55 s | 8 Carrion Swarm (S), 6 Hive Host | 0.9 | stealth air | 2,130 |
| 14 | 60 s | 20 Shambler (S), 10 Plated Husk, 6 Stitcher | 0.6 | | 2,840 |
| 15 | 60 s | 16 Carrion Swarm, 6 Hive Host, 6 Sparkhead | 0.7 | | 3,590 |
| 16 | 60 s | 20 Plated Husk (S), 8 Stitcher | 0.6 | stealth armour | 4,480 |
| 17 | 60 s | 40 Sprinter, 8 Sparkhead | 0.4 | rush | 1,870 |
| 18 | 65 s | 20 Carrion Swarm, 10 Hive Host (S), 6 Stitcher | 0.6 | | 5,810 |
| 19 | 75 s | 25 Plated Husk, 20 Carrion Swarm (S), 10 Sparkhead, 8 Stitcher | 0.5 | everything | 8,470 |
| 20 | 70 s | 20 Carrion Swarm, 12 Hive Host, 8 Sparkhead | 0.6 | air + splitter mass | 6,830 |
| 21 | 70 s | 30 Plated Husk, 10 Sparkhead (S) | 0.5 | stealth stunners | 6,600 |
| 22 | 100 s | 20 Carrion Swarm, then **2 × Gristle** | 1.0 | double mini-boss | 7,230 |
| 23 | 70 s | 50 Sprinter (S), 10 Stitcher | 0.35 | stealth rush | 3,360 |
| 24 | 75 s | 15 Hive Host, 25 Carrion Swarm (S), 10 Sparkhead | 0.5 | *(Ironwall/Overrun only)* | 9,420 |
| 25 | 75 s | 40 Plated Husk (S), 12 Stitcher | 0.45 | | 10,210 |
| 26 | 75 s | 30 Carrion Swarm (S), 20 Hive Host | 0.5 | | 10,220 |
| 27 | 110 s | 30 Plated Husk, 10 Sparkhead, then **3 × Gristle** | 0.6 | triple mini-boss | 16,590 |
| 28 | 80 s | 80 Sprinter (S), 20 Stitcher, 20 Sparkhead | 0.3 | | 11,370 |
| 29 | 90 s | 40 Plated Husk (S), 30 Carrion Swarm (S), 15 Hive Host (S), 15 Stitcher | 0.4 | everything, stealthed | 20,710 |
| **Boss wave** | ∞ | 12 Plated Husk, 8 Stitcher, 6 Sparkhead, then **Mother Blight** | 0.8 | **final boss** | escort ≈ 5,290 at w24 + boss 40,000 |

### 6.3 Balance targets (Sentinel; tuning guidance)
- **Cumulative cash** (start $800, $1 per HP of health damage, wave bonuses, no depots): about $1.5k at the start of wave 4, $5.7k at wave 9, $7.1k at wave 10, $20k at wave 15, $44k at wave 20, $64k at wave 23, and **≈ $68k entering wave 24 (the boss)**. Depots should add roughly 20–35% for a greedy player.
- **Typical endgame:** two tier-5 towers (≈ $11–18k each) plus three or four tier-3/4 towers plus support.
- **Detection checks:** a player using only Picket Top cannot clear wave 8 (stealth) without Thermal Visor, and cannot clear waves 7/9/13 (air) without an air-capable tower.
- Wave 6 (12 Plated Husks, 40% kinetic resistance) should leak against a kinetic-only defence that lacks Breacher Kit / AP Core.
- Waves 10 and 22 (Gristle) should kill one or two careless expensive towers if no bait or spacing is used.
- **Mother Blight** (40,000 effective HP, ≈ 100 s exposure) needs ≈ 400–500 effective DPS across the path.
- First-time players should win Sentinel about 40–50% of the time and Recruit about 85%+. Ironwall/Overrun are for experienced players.

### 6.4 Radio tips (Sgt. Okafor; original text, write the rest in the same voice)
- W1: "Halcyon, this is Okafor. Blighted coming up Cinder Pass. Put a Picket on that first bend."
- W3: "Sprinters! They hit the road fast, so cover a long stretch."
- W5: "Those Husks are wearing riot plate. Bullets bounce. Rockets don't."
- W6 (shown during W5): "Plenty more plated ones next wave. Mix up your damage types."
- W7 (shown during W6): "Birds! Infected birds! Arc Masts and Longshots can swat 'em."
- W8 (shown during W7): "Thermals are picking up ghosts. Get stealth detection up before the next wave."
- W10: "Big fella inbound. Calls him Gristle. He throws rubble at the nearest tower, so give him something cheap to chew on."
- W12: "Sparkheads pop like transformers. Keep your best gear out of the blast."
- Final wave: "That's her. Mother Blight. Everything you've got, Halcyon!"

### 6.5 Difficulty modes (picked on the title screen)

| Field | **Recruit** (easy) | **Sentinel** (default) | **Ironwall** (hard) | **Overrun** (expert, optional 4th) |
|---|---|---|---|---|
| Tagline (original) | "First week on the line." | "Hold the pass." | "No one gets through." | "They just keep coming." |
| `wave_count` / final boss wave | **16** / wave 16 | **24** / wave 24 | **30** / wave 30 | **30** / wave 30 |
| Regular waves played | 1–15 | 1–23 | 1–29 | 1–29 |
| Mini-boss (Gristle) waves | 10 | 10, 22 (×2) | 10, 22 (×2), 27 (×3) | 10, 22 (×2), 27 (×3) |
| `enemy_hp_mult` (non-boss) | 0.75 | 1.0 | 1.25 | 1.5 |
| `boss_hp_mult` (Gristle + Mother Blight) | 0.4 | 1.0 | 1.75 | 2.5 |
| `enemy_speed_mult` | 0.9 | 1.0 | 1.1 | 1.2 |
| `start_cash` | $1,000 | $800 | $700 | $600 |
| `base_hp` | **800** | **500** | **400** | **300** |
| `income_mult` (damage cash, wave bonus, depots) | 1.0 | 1.0 | 0.9 | 0.8 |
| `sell_ratio` | 0.5 | 0.5 | 0.5 | 0.5 |
| `tower_hp_enabled` | **false** (bosses' tower attacks are visual only) | true | true | true |
| `stealth_from_wave` | – | – | – | **20** (every enemy from wave 20 on is stealthed) |
| Mother Blight effective HP | 16,000 | 40,000 | 70,000 | 100,000 |
| Gristle effective HP (each) | 1,200 | 3,000 | 5,250 | 7,500 |
| ≈ Cash entering final wave | ≈ $18.8k | ≈ $68k | ≈ $162k | ≈ $175k |

**How the wave list extends or truncates:**
- Each mode plays master regular waves **1…(N−1)** in order, then the **boss wave** as wave **N**.
- Recruit **truncates** after regular wave 15. Sentinel uses regular waves 1–23. Ironwall and Overrun **extend** to regular wave 29.
- The **final boss is always wave N**: Recruit 16, Sentinel 24, Ironwall 30, Overrun 30.
- `hp_mult(w)` always uses the actual wave number, so Recruit's boss escort on wave 16 is scaled at w16 × 0.75.
- The wave-start bonus also uses the actual wave number.
- `waves.json` must contain at least `max(wave_count) − 1 = 29` regular waves. The game validates this at load and shows an error if a mode asks for more waves than exist.

**Leak check per mode** (biggest single non-boss enemy on the last regular wave, at full health, vs base HP; boss multiples vs base HP):

| Mode | Last regular wave, hp_mult | Plated Husk / Stitcher / Hive Host full-HP leak | Base HP | Survive one worst leak? | Gristle ÷ base | Mother Blight ÷ base |
|---|---|---|---|---|---|---|
| Recruit | w15, 1.28 | 102 / 153 / 191 | 800 | yes, easily (24%) | 1.5× (survivable below 66% HP) | 20× |
| Sentinel | w23, 2.10 | 168 / 252 / 315 | 500 | yes, once (63%) | 6× | 80× |
| Ironwall | w29, 3.00 | 240 / 360 / 450 | 400 | a Husk or Stitcher yes; an untouched Hive Host is a loss (hard-mode tension) | 13× | 175× |
| Overrun | w29, 3.60 | 288 / 432 / 540 | 300 | only a Husk, barely | 25× | 333× |

On every mode, small leaks (Shamblers, Sprinters, damaged enemies) are survivable, and a boss leak is a loss unless the boss arrives almost dead.

---

## 7. Economy summary

| Parameter | Sentinel value | Per-mode? | Notes |
|---|---|---|---|
| Starting cash | **$800** | yes (`start_cash`) | TDX: 975 Easy / 725 Intermediate |
| Damage income | **$1 per 1 HP of health damage** (not shield, not overkill, not no-cash spawns) × `income_mult` | mult | TDX pays per damage dealt |
| Wave-start bonus | **($75 + $25 × wave) × `income_mult`** | mult | |
| Skip bonus | $0 | – | TDX has none |
| Sell refund | **50%** of total spent | `sell_ratio` (0.5 in all modes) | confirmed |
| Base HP | **500** | yes (`base_hp`) | §2.1 |
| Leak damage | **ceil(remaining HP + remaining shield)** | – | same rule in all modes, bosses included |
| Supply Depot | $100/wave base → up to $2,000 (Convoy Contract) | × `income_mult` | |

All values live in `data/game_config.json` and `data/difficulties.json` (§10).

---

## 8. UI / HUD

**Title screen (new):**
- **BLIGHTLINE** logo (self-made text treatment), a slowly orbiting camera over Cinder Pass in the background, and buttons **Play / Settings / Quit**.
- **Play** opens the **Mode Select** panel with 4 cards (Recruit, Sentinel, Ironwall, Overrun). Each card shows: name, tagline, a 1–4 skull difficulty rating, **wave count**, **base HP**, **starting cash**, enemy HP/speed multipliers, and notes (e.g. "Towers can't be destroyed" on Recruit, "All enemies stealthed from wave 20" on Overrun).
- **Sentinel is pre-selected.** Arrow keys or mouse choose a card. **Deploy** (or Enter) starts the match. **Back** (or Esc) returns.
- The last chosen mode is remembered for the session.

**In-match HUD** (`CanvasLayer`, 1920×1080 base, scales):
1. **Top-left:** **mode badge** (e.g. `SENTINEL`, coloured per mode), base HP bar with number (`♥ 487 / 500`), wave counter **`Wave 7 / 24`** (the total comes from the mode), and the wave timer countdown.
2. **Top-centre:** **boss health bar** (name, HP, shield segment), only while Gristle or Mother Blight is alive.
3. **Top-right:** cash `$ 1,250` and speed/pause buttons (`1x`/`1.5x`/`2x`, `II`).
4. **Bottom-centre:** **6-slot hotbar.** Each slot shows icon, name, cost and hotkey number. Slots are greyed when unaffordable. Supply Depot shows `n/6`.
5. **Right side: selected-tower panel.** Name; level `top-bottom` with **two rows of 5 tier pips**; HP bar (hidden on Recruit); stats (damage + type icon, reload, range, DPS, pierce/splash/chains); detection icons (stealth, air); **Top and Bottom upgrade buttons** showing next-tier name, cost, stat deltas, and a lock icon with "path capped at 2" text when the cross-path rule blocks it ("MAX" at tier 5); targeting selector `◀ First ▶` (C/V); ability button with cooldown sweep (G); **Sell $N**; total damage dealt.
6. **Bottom-right:** **Skip Wave** button plus a next-wave preview (enemy icons with stealth/air badges; "FINAL WAVE" on wave N).
7. **Bottom-left:** **radio box** with a Sgt. Okafor portrait placeholder and one line of text.
8. **World-space:** enemy health bars (shield segment, camo pattern for stealth, resistance chips on hover), range ring, stun icon over stunned towers, damage numbers (optional), and a **"−N" base-damage popup at the gate on every leak**.
9. **Hover tooltips:** over enemies, show name, HP/shield, resistances, traits. Over hotbar slots, show base stats.

**Other screens:** Pause menu (Resume, Restart same mode, Settings, Quit to title). **Victory/Defeat** screen shows the mode name, waves survived (`19 / 24`), base HP left, total damage, cash earned and towers built, with **Restart (same mode)**, **Change Mode** and **Title** buttons. Settings: master/SFX/music volume, fullscreen, damage numbers.

---

## 9. Art and audio placeholder guidance

- **No ripped or third-party game assets.** Build everything from Godot primitives/CSG or from **self-made** low-poly models (Blender → glTF). CC0 assets are allowed only with a `CREDITS.md` entry and licence file; prefer self-made.
- **Towers** (olive/khaki with teal markings; each tier adds a visible part; colour accent per path: Top = gold, Bottom = red; tier 5 gets a distinct silhouette change):
  - Picket: capsule soldier with helmet, behind a sandbag ring.
  - Lobber: two capsules plus a tube launcher.
  - Frostline Engineer: soldier with a white backpack tank and a blue nozzle.
  - Arc Mast: tall lattice pylon with a glowing coil sphere.
  - Longshot: raised wooden platform with a long barrel.
  - Supply Depot: tent plus crate stack and a small truck primitive that drives in on payout.
- **Blighted** (sickly green/purple with glowing fungal nodules):
  - Shambler: hunched capsule.
  - Sprinter: thin, leaning-forward capsule.
  - Plated Husk: wide capsule with grey box riot plates.
  - Carrion Swarm: a cluster of 6–8 small dark tetrahedra orbiting a point.
  - Hive Host: big sphere body with pustule spheres.
  - Stitcher: capsule with a green cross-shaped glow and a satchel.
  - Sparkhead: capsule with a yellow coil and spark particles.
  - Gristle: 1.5× bulky capsule with a vest.
  - Mother Blight: 4× scale, a multi-sphere fungal mass with a cocoon-sac tail.
  - Shield = translucent blue sphere. Stealth = 35% alpha.
- **VFX:** sparks and muzzle flashes; green spore puffs on death (no blood); tracer lines; a zigzag `ImmediateMesh` arc for Arc Mast; frost tint lerped by chill %; bile blob projectile for Mother Blight.
- **Audio:** self-generated SFX (sfxr-style synth or self-recorded) for rifle, rocket, explosion, zap, freeze, zombie groan, death "pop", cash, leak alarm, wave-start siren, boss roar, UI click. Music optional. Use Master/SFX/Music buses.

---

## 10. Data-driven architecture

Keep all tuning in text data. **Recommended: JSON** in `res://data/`, loaded at startup into typed GDScript classes (`TowerDef`, `UpgradeDef`, `EnemyDef`, `WaveDef`, `DifficultyDef`). `.tres` Resources are an acceptable alternative with the same fields.

```
res://data/game_config.json   # cash_per_hp, wave bonus base/step, hp_mult slope (0.05), skip_bonus_per_sec, tower regen %, default_difficulty
res://data/difficulties.json  # 4 modes (fields below)
res://data/towers.json        # 6 towers: base stats + top[5] + bottom[5] upgrade deltas
res://data/enemies.json       # 7 regular + gristle + mother_blight
res://data/waves.json         # "waves": [29 regular waves], "boss_wave": {...}
res://data/map_cinder_pass.json # path waypoints, path width, blockers, bounds (or keep these in the .tscn)
```

`difficulties.json`:
```json
{
  "default": "sentinel",
  "modes": [
    {"id": "recruit",  "name": "Recruit",  "tagline": "First week on the line.", "rating": 1,
     "wave_count": 16, "enemy_hp_mult": 0.75, "boss_hp_mult": 0.4,  "enemy_speed_mult": 0.9,
     "start_cash": 1000, "base_hp": 800, "income_mult": 1.0, "sell_ratio": 0.5,
     "tower_hp_enabled": false, "stealth_from_wave": null},
    {"id": "sentinel", "name": "Sentinel", "tagline": "Hold the pass.", "rating": 2,
     "wave_count": 24, "enemy_hp_mult": 1.0,  "boss_hp_mult": 1.0,  "enemy_speed_mult": 1.0,
     "start_cash": 800,  "base_hp": 500, "income_mult": 1.0, "sell_ratio": 0.5,
     "tower_hp_enabled": true,  "stealth_from_wave": null},
    {"id": "ironwall", "name": "Ironwall", "tagline": "No one gets through.", "rating": 3,
     "wave_count": 30, "enemy_hp_mult": 1.25, "boss_hp_mult": 1.75, "enemy_speed_mult": 1.1,
     "start_cash": 700,  "base_hp": 400, "income_mult": 0.9, "sell_ratio": 0.5,
     "tower_hp_enabled": true,  "stealth_from_wave": null},
    {"id": "overrun",  "name": "Overrun",  "tagline": "They just keep coming.", "rating": 4,
     "wave_count": 30, "enemy_hp_mult": 1.5,  "boss_hp_mult": 2.5,  "enemy_speed_mult": 1.2,
     "start_cash": 600,  "base_hp": 300, "income_mult": 0.8, "sell_ratio": 0.5,
     "tower_hp_enabled": true,  "stealth_from_wave": 20}
  ]
}
```
The final boss wave is always `wave_count`. There is no separate field, which avoids mismatches.

`towers.json` entry (shape only):
```json
{
  "id": "picket", "name": "Picket Trooper", "cost": 250, "hp": 100, "footprint": 1.2,
  "base": {"damage": 2, "damage_type": "kinetic", "burst": 3, "burst_gap": 0.12, "reload": 1.5,
           "range": 10, "air": false, "stealth": false, "splash": 0, "pierce": 1, "chains": 0},
  "top": [
    {"name": "Scope Rail", "cost": 150, "delta": {"range": 3}},
    {"name": "Drill Sergeant", "cost": 350, "delta": {"damage": 1, "reload": -0.2}},
    {"name": "Thermal Visor", "cost": 800, "delta": {"burst": 2, "reload": -0.3}, "flags": ["stealth"]},
    {"name": "Heavy Rounds", "cost": 2200, "delta": {"damage": 5, "range": 2}},
    {"name": "Squad Automatic", "cost": 7000, "delta": {"damage": 6, "range": 3},
     "set": {"fire_mode": "auto", "auto_interval": 0.15}}
  ],
  "bottom": [ "...5 entries..." ]
}
```
`waves.json` entry:
```json
{"wave": 8, "timer": 50, "radio": "Thermals are picking up ghosts...",
 "groups": [{"enemy": "sprinter", "count": 10, "spacing": 0.8, "stealth": true},
            {"enemy": "plated_husk", "count": 10, "spacing": 0.8}]}
```

**Suggested layout:**
- `Title.tscn` (title + mode select) → `Match.tscn`. The match contains the map plus `GameState` (holds the active `DifficultyDef`), `WaveManager` (builds the wave sequence from mode + waves.json), `Economy`, `PlacementController`, `CameraRig` and `HUD`.
- `towers/Tower.tscn`: one generic scene configured by `TowerDef`, with attack behaviours `burst`, `auto`, `projectile_splash`, `salvo`, `frost_spray`, `chain`, `beam`, `hitscan`, `economy`.
- `enemies/Enemy.tscn`: generic, `PathFollow3D`-based, with trait components `Splitter`, `Healer`, `DeathStun` and `BossAbilities`.
- Use `Engine.time_scale` for speed and `get_tree().paused` for pause, with the camera and UI on `PROCESS_MODE_ALWAYS`.

**Debug (dev builds only):** F1 +$10,000, F2 kill all, F3 jump to wave N, F4 god-mode base, F5 force-leak the nearest enemy (to test §2.1). All are disabled in release export.

---

## 11. MVP acceptance criteria (for TD Reviewer)

**Build and platform**
1. The project opens in Godot 4.x with no errors. All gameplay code is GDScript.
2. A Windows export preset exists. The exported `.exe` launches on Windows 10/11 to the title screen without the editor installed.
3. Deploying from mode select loads a match in under 10 s. Quit returns to desktop cleanly.
4. ≥ 50 FPS at 1080p on Sentinel wave 23 at 2x speed on a mid-range laptop (or no visible stutter on the reviewer's machine).

**Map and placement**
5. The Cinder Pass map matches §2: spawn on the left, base on the right, one serpentine road of ≈140 m with the 9 waypoints, and blockers present.
6. Ground enemies walk the road centreline (±0.6 m). Air enemies follow it at ≈4 m height.
7. The placement ghost shows a range ring, a green/red validity tint, and cost. Placement is rejected on the road, on blockers, outside bounds, or overlapping another tower's footprint.
8. Holding Shift while placing keeps the same tower selected. Q/Esc cancels.
9. The 7th Supply Depot cannot be placed, and the hotbar shows `6/6`.

**Camera and controls**
10. RMB-drag orbits (pitch clamped 30°–80°), WASD/arrows and MMB-drag pan within bounds, the wheel zooms 12–60 m, and Home resets the camera. There is no player avatar.
11. Hotkeys work as in §3: 1–6, LMB, Q, E, R, Ctrl+E, Ctrl+R, C, V, G, Backspace/Delete, Space, F, P/Esc, T.
12. Camera and UI keep working while paused and at every speed.

**Towers and upgrades**
13. All 6 towers exist with the base stats and costs from `towers.json`, matching §4.
14. Each tower has a Top and a Bottom path of **5 tiers** (60 upgrades in total). Tiers must be bought in order, and costs are deducted correctly.
15. **Cross-path cap:** once a path reaches tier 3, the other path cannot go above tier 2 (the UI shows it locked). `5-2` and `2-5` are reachable. `3-3`, `4-3` and `5-3` are impossible. Ctrl+E/Ctrl+R stop at the cap or when cash runs out.
16. Stat changes apply as additive deltas, and "set" overrides apply. The panel shows current stats, a next-tier preview, and 5 tier pips per path.
17. Targeting modes First / Last / Strongest / Weakest / Closest cycle with C/V and visibly change which enemy is shot.
18. Towers without stealth detection never choose a stealth enemy as their primary target. Splash/chain/pierce can still damage stealth enemies.
19. Towers without air targeting never target the Carrion Swarm. Arc Mast and Longshot hit air at base level, Lobber at Top T4+, and Frostline Engineer at Bottom T4+.
20. Resistances reduce damage by the listed % per type, and "ignore resistance" upgrades bypass them. For example, a base Picket does 60% damage to a Plated Husk, while a Picket at Bottom T3 does 100%.
21. Frostline chill slows enemies in proportion to chill and freezes them at full chill (1.5 s, or 2.5 s with Whiteout). Bosses never freeze except through Cryo Lance T4/T5.
22. Abilities (Frag Toss I/II, Overcharge) trigger with G or the button, show their cooldown, and are blocked while on cooldown or while the tower is stunned.
23. Selling refunds 50% of total spent (`sell_ratio`) and removes the tower.
24. A Supply Depot pays its listed amount × `income_mult` at each wave end. Top T3+ restores base HP up to the mode's starting base HP, never above it.

**Enemies**
25. All 7 regular enemies, Gristle and Mother Blight have the HP, shield, speed, resistances and traits from `enemies.json`, matching §5.
26. Shield is depleted before HP, shows as a blue segment, and pays no cash.
27. A Hive Host death spawns 4 no-cash Sprinters, and they inherit stealth.
28. Stitchers heal nearby allies on their interval. A Sparkhead death stuns towers within 6 m for 2.5 s.
29. Gristle (waves 10, 22, and 27 where played) damages the closest tower with Rubble Throw. Towers can be destroyed at 0 HP (except on Recruit). Towers regain 10% HP at each wave start.
30. Mother Blight shows the top boss bar and uses Bile Mortar, Quake Stomp, Brood Call and Frenzy as specified.

**Waves, economy and flow**
31. Wave compositions, order, spacing and timers match `waves.json` / §6.2, after a 20 s wave-0 prep.
32. The next wave starts automatically when the timer ends. Skip/Space is available only after all of the current wave's enemies have spawned.
33. Cash rises by `1 × income_mult` per HP of health damage (none for shield, overkill or no-cash spawns). The wave-start bonus is `(75 + 25 × wave) × income_mult`.
34. Game speed cycles 1x → 1.5x → 2x and pause freezes the simulation. Spawns, reloads, abilities and timers all scale correctly.

**HUD, data and originality**
35. The HUD shows every element in §8 (mode badge, base HP, wave `n / N`, timer, cash, hotbar, tower panel with tier pips, skip, next-wave preview, radio line, boss bar during boss waves, leak popups).
36. Changing a number in any `data/*.json` file changes in-game behaviour on the next run, with no code edits.
37. No asset, name or text from TDX or any other game appears in the project. The title, faction, towers, enemies, bosses and advisor use the names in this brief. Any CC0 asset is credited.
38. Victory/Defeat screens show the mode, waves survived and stats, and offer Restart (same mode), Change Mode and Title. Restart fully resets state.
39. Playtest sanity: an experienced tester wins Sentinel within two attempts. A defence with no stealth detection by wave 8 leaks stealth enemies.
40. Ctrl+E/Ctrl+R and the panel never let a tower exceed tier 5 or break the cap. Tier-5 upgrades show "MAX" afterwards.

**Leak rule (v1.1)**
41. When any enemy reaches the gate, base HP drops by exactly **ceil(its remaining HP + remaining shield)** and the enemy is removed. Verify with a damaged enemy: e.g. a Plated Husk on Sentinel wave 5 (HP 72, shield 24) at 30 HP and 0 shield costs exactly 30. A full-health one at that wave costs 96.
42. There is no fixed leak value, minimum, or boss special-case. Gristle and Mother Blight leaks use the same formula, so a Mother Blight forced to leak with ≤ 499 effective HP on Sentinel leaves the base alive. No-cash spawns leak by the same formula.
43. A "−N" popup at the gate and the base HP bar both reflect the exact leak amount. Base HP reaching 0 triggers Defeat immediately, even mid-wave.

**Difficulty modes (v1.1)**
44. The title screen offers mode select with Recruit, Sentinel, Ironwall and Overrun cards, each showing the values from `difficulties.json`. Sentinel is pre-selected. The chosen mode starts the match.
45. Starting base HP per mode is **800 / 500 / 400 / 300**, and starting cash is **$1,000 / $800 / $700 / $600**.
46. Enemy HP/shield = base × `(1 + 0.05 × (w − 1))` × `enemy_hp_mult`. Speed = base × `enemy_speed_mult`. Gristle and Mother Blight HP/shield = base × `boss_hp_mult`. Verify one enemy per mode via a debug overlay or tooltip (e.g. a Shambler on wave 1 has 7.5 / 10 / 12.5 / 15 HP, displayed rounded).
47. `income_mult` scales damage cash, wave bonuses and depot payouts. `sell_ratio` scales sell refunds. `tower_hp_enabled = false` on Recruit means towers take no damage.
48. Wave count per mode is **16 / 24 / 30 / 30**. The HUD shows `Wave n / N` accordingly.
49. The final wave of every mode is the boss wave with Mother Blight: **wave 16 (Recruit), 24 (Sentinel), 30 (Ironwall, Overrun)**. The regular waves played are 1–15, 1–23, 1–29 and 1–29 respectively.
50. Overrun spawns every enemy as stealthed from wave 20 onward. Other modes keep the per-wave stealth flags.
51. **Win/lose per mode:** Victory triggers only after the mode's final wave is cleared with base HP > 0, for example not after wave 16 on Sentinel. Defeat triggers whenever base HP ≤ 0 in any mode.
52. Adding a mode to `difficulties.json` (or changing `wave_count` up to 30) works without code changes. A `wave_count` above (regular waves available + 1) shows a clear load-time error rather than crashing.

---

## 12. Scope

**In MVP (v1.1):**
- 1 map
- 6 towers × 2 paths × 5 tiers
- 7 enemies, a mini-boss and a final boss
- 29-wave master list plus a boss wave
- **4 difficulty modes** on the title screen
- the leak rule from §2.1
- tower HP (bosses only)
- free overhead camera
- full HUD, data-driven JSON

**Post-MVP (out of scope for the first build):**
1. **Line of sight and terrain height** (raycasts from muzzles, obstacles that block shots, high ground giving +15% range).
2. More towers (support/buff tower, vehicle-spawner motor pool, medic tent that heals towers, cheap bait sentry with rebuilds) and a larger roster with a 6-slot loadout chosen before the match.
3. More enemy traits: regular enemies that damage towers, a cloner that duplicates nearby enemies on death, summoners, 80–90% single-type resistances, shield regen, speed-buff auras, and more mini-bosses.
4. Endless mode (beyond wave 30 with scaling), additional maps (water lanes, multiple paths), co-op.
5. Power-ups (one-shot air strikes or crates), progression and unlocks, cosmetics, best-wave records per mode.
6. A retry-wave ("rewind") option after a defeat.
7. Art pass, music, localisation, controller support, key remapping UI, saved settings.
8. Skip-wave cash bonus, auto-skip toggle, placement rotation, 0.5x slow mode.

---

## 13. Open design questions

None at the moment. All v1.0 questions were resolved by Adamas on 16 Nov 2026: free overhead camera with no avatar; tower HP with only bosses damaging towers; 5 tiers per path; 50% sell refund; military-vs-zombies theme with all-new names; 24-wave default. Raise new questions with TD Researcher if playtesting exposes them, for example whether Overrun should ship in the MVP or be unlocked by beating Ironwall.

---

## Appendix A: Research notes (facts observed, paraphrased; sources linked)

**Primary reference: Tower Defense X (Roblox)**
- **Dual-path upgrades:** towers have a top and bottom path, 5 tiers each. Once one path reaches tier 3+, the other is limited to 2 (max 5-2 / 2-5). The starter rifleman's top path adds range, DPS and stealth detection at tier 3. Its bottom path adds ignore-bullet-resistance at tier 3 and a grenade ability at tier 4. [TDX wiki: Ranger](https://tdx.fandom.com/wiki/Ranger), [NamuWiki: TDX](https://en.namu.wiki/w/Tower%20Defense%20X)
- **Starter tower numbers (for scale):** placement $250, HP 100, range 9 studs, burst of 2 shots at 1 damage, reload 1.75 s. Upgrades range from $165 to $8,750, and a maxed tower costs ~$12k. [TDX wiki: Ranger](https://tdx.fandom.com/wiki/Ranger)
- **Rocket tower:** $850, 40 explosive damage, 2-stud splash, reload 7.5 s, range 20. The top path gains stealth at tier 3 and air targeting at tier 5. The bottom path gains ignore-explosive-resistance at tier 3. [TDX wiki: Missile Trooper](https://tdx.fandom.com/wiki/Missile_Trooper)
- **Freeze tower:** deals 0 damage until tier 3. It drains an enemy "body heat" meter: enemies slow as it drops and are frozen at 0. Bosses resist. [TDX wiki: Cryo Blaster](https://tdx.fandom.com/wiki/Cryo_Blaster)
- **Damage types and resistances:** about 10 types (bullet, fire, explosive, laser, ice, toxic, melee, golden/energy, collision, lightning). Enemies carry % resistances (e.g. 15%, 60%, 92% bullet). Some upgrades ignore a resistance. [TDX wiki: Towers](https://tdx.fandom.com/wiki/Towers), [Attributes](https://tdx.fandom.com/wiki/Attributes)
- **Enemy attributes:** stealth (only stealth-detecting towers can target; translucent body, camo health bar; *any* enemy can be stealthed), airborne (needs air targeting; splash can transfer), shield (extra HP, pays no cash), no-cash spawns, boss (top-of-screen health bar, stun-immune), and "destroys base". [TDX wiki: Attributes](https://tdx.fandom.com/wiki/Attributes), [Enemies](https://tdx.fandom.com/wiki/Enemies)
- **Tower HP:** towers have HP in most modes. Bosses and some enemies shoot, stun or debuff towers, and towers die at 0, so cheap towers are used as bait. Easy mode has no tower HP. Automatic tower recovery was added later. [TDX wiki: Towers](https://tdx.fandom.com/wiki/Towers), [Easy Mode](https://tdx.fandom.com/wiki/Easy_Mode), [Status Effects](https://tdx.fandom.com/wiki/Status_Effects_(Towers))
- **Economy:** cash comes mainly from damaging enemies (150% of damage dealt, split between players) and a per-wave bonus that grows later. Selling refunds 50%. Some enemies are flagged no-cash. [TDX wiki: Currency](https://tdx.fandom.com/wiki/Currency)
- **Farm/economy tower:** costs $375, placement limit 10, and drops a $100 crate every wave. Its bottom path scales to ~$1,700/wave. Payback is ~4–5 waves. Upgrades apply from the next wave. [TDX wiki: Farm](https://tdx.fandom.com/wiki/Farm)
- **Modes and numbers:** Easy has 24 waves, base health 500, starting cash 975, and a ~59 s timer for most waves. Intermediate has 32 waves, base 300, and $725 starting cash. Expert has 42 waves and base 250. Waves introduce one new threat at a time (fast → shielded heavy → armoured → stealth → splitter → final boss), with advisor lines each wave. [Easy Mode](https://tdx.fandom.com/wiki/Easy_Mode), [Intermediate Mode](https://tdx.fandom.com/wiki/Intermediate_Mode), [Expert Mode](https://tdx.fandom.com/wiki/Expert_Mode)
- **Enemy scale (Easy):** basic 8 HP at 2.8 speed; fast 8 HP at 6.5; heavy 30 HP + 10 shield at 1.9; armoured 100 HP with 15% bullet resistance at 1.5; on-death splitters; final boss 45,000 HP with stun/heal/debuff abilities. [TDX wiki enemy pages](https://tdx.fandom.com/wiki/Zombie)
- **Enemy archetypes in other modes:** air drones that slash towers; a spawner that tosses grenades which spawn minions (cooldown 14 s); a "multiplier" that clones nearby enemies on death (clones +30% speed, no cash); stunners (on death / ground slam). [Multiplier 1](https://tdx.fandom.com/wiki/Multiplier_1), [Grenadier (Enemy)](https://tdx.fandom.com/wiki/Grenadier_(Enemy)), [Skull Drone](https://tdx.fandom.com/wiki/Skull_Drone)
- **Placement and line of sight:** place anywhere (land/sea/air distinction). Towers need line of sight to the path, and obstacles block shots. [TDX Tutorial Mode](https://tdx.fandom.com/wiki/Tutorial_Mode), [TDX controls guide](https://towerdefensexbeta.wiki/guides/controls/)
- **PC controls:** 1–6 select a tower, Q cancels/deselects, LMB places/selects, Shift keeps placing, E/R upgrade top/bottom, Ctrl+E/R max a path, C/V cycle targeting, G/H/J abilities, Backspace sells. Targeting modes are First, Last, Strongest, Weakest, Closest. [TDX wiki: Keybinds](https://tdx.fandom.com/wiki/Keybinds), [controls guide](https://towerdefensexbeta.wiki/guides/controls/)
- **Speed and skip:** a speed control (0.5x/1.5x; free in solo since 2024), skip-wave voting, auto-skip, and a 6-tower loadout. [TDX wiki: Gamepasses](https://tdx.fandom.com/wiki/Gamepasses), [Update Log](https://tdx.fandom.com/wiki/Update_Log), [NamuWiki](https://en.namu.wiki/w/Tower%20Defense%20X)

**Secondary references**
- **Tower Defense Simulator (Roblox):** seven targeting modes (First, Last, Strongest, Weakest, Closest, Farthest, Random); hidden enemies need detection but splash/pierce can hit them; Easy starting cash $500, base health 100; sell returns a stated reduced amount; sniper-type towers detect flying enemies. [TDS wiki: How to Play](https://tds.wiki/w/How_to_Play), [Hidden](https://tds.wiki/w/Hidden_(Attribute)), [Easy Mode](https://tds.wiki/w/Easy_Mode), [Sniper](https://tds.wiki/w/Sniper)
- **Bloons TD 6:** starting cash $650; end-of-round bonus $100 + round number; sell-back 70%; pop income tapers after round 50 to stop late snowballing; targeting First/Last/Close/Strong plus an optional camo priority; income towers take ~10–15 rounds to pay off. [Bloons wiki: Cash](https://www.bloonswiki.com/Cash), [BTD6 rounds and economy](https://teemo.dev/game-design/bloons-td-6/systems/rounds-and-economy/), [Targeting Priority](https://bloons.fandom.com/wiki/Targeting_Priority), [Strategy](https://www.bloonswiki.com/Strategy:Bloons_TD_6)
- **Kingdom Rush:** armour reduces physical damage and magic resistance reduces magic damage, in bands (Low 1–30%, Medium 31–60%, High 61–90%); explosive damage meets half armour; flying enemies can't be targeted by artillery but take splash; 20 lives per stage, bosses cost 20 lives; calling a wave early pays bonus gold per second remaining. [KR wiki: Armor and Magic resistance](https://kingdomrushtd.fandom.com/wiki/Armor_and_Magic_resistance), [wikily: Enemies](https://wikily.gg/kingdom-rush/enemies), [wikily: Game modes](https://wikily.gg/kingdom-rush/game-modes)

**Genre conventions distilled → our choices**
| Convention | Typical numbers seen | Our MVP |
|---|---|---|
| Sell refund | 50% (TDX) / 70% (BTD6) / reduced fixed (TDS) | 50% |
| Starting cash | $500–$975 | $800 |
| Base health / lives | 100–500 HP (Roblox), 20 lives (KR) | 800 / 500 / 400 / 300 by mode; leak = remaining HP + shield |
| Wave bonus | flat + growing per wave | $75 + $25·wave |
| Kill income | per damage (TDX/TDS), per pop (BTD), per kill (KR) | $1 per HP damage |
| Targeting | First/Last/Strongest/Weakest/Closest (+Farthest/Random) | 5 modes |
| Detection gates | stealth/camo/hidden, flying/air, lead/armour | stealth + air + kinetic armour |
| Upgrade shape | dual path with cap (TDX), 3 paths (BTD6), linear (TDS/KR) | dual path 5 tiers, 5/2 cap (TDX rule) |
| Speed | 0.5x/1.5x (TDX), 2x/3x (BTD) | 1x/1.5x/2x |
| Wave flow | timed auto-start + skip (TDX/TDS), manual + early-call bonus (KR) | timed + skip, no bonus |
| Difficulty modes | TDX: Easy 24 waves/500 base, Intermediate 32/300, Expert 42/250; TDS: Easy…Fallen vote | Recruit 16 / Sentinel 24 / Ironwall 30 / Overrun 30 |
