# Brainrot Catch

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Iksantamfan/brainrot-catch/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Iksantamfan/brainrot-catch/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Catch** is a 3D Roblox game for make.fun's `roblox-brainrot-01` bounty ("Make the best AI Roblox brainrot game"). Not a Steal a Brainrot clone and not a conveyor game: absurd animal-plus-object hybrids roam a colourful 3D map, you catch them in the wild, and you dash home to your base before the wave sweeps the map.

## How to play

1. **Hunt.** Twelve original hybrids roam the wild field — Wobble Capybucket (capybara + bucket), Honk Hose (goose + garden hose), Fridge Rex (T-Rex + refrigerator), Skibidi Skunk-Subwoofer (skunk + subwoofer), Mogging Moose-Monolith (silver moose + black monolith) and seven more, across seven rarities from Common to Secret.
2. **Catch.** Walk up to one and press **E** (or the big green CATCH button). Rarer characters take longer to channel — a Secret takes 20 seconds. The server validates the catch: more than 15 studs away and it is rejected.
3. **Dash home.** Carrying slows you down (10% per tier, up to −70% for a Secret). Press **Shift** to dash. Get inside your own base and the character slots in and starts earning money every second.
4. **Survive the wave.** Every 180 seconds a storm wave sweeps the map from the sea side, after a 30-second warning (siren, darkening sky, countdown). Caught carrying outside your base, your character escapes back into the wild.
5. **Grow.** Money buys base slots (up to 20), and at $5,000,000 you can rebirth for a permanent income multiplier (up to x3.5). Mutations (Gold x2, Diamond x4, Rainbow x8, Lava x3) multiply a character's income. Fill the index book (all 12) for a $1,000,000 bonus. Watch for 2x income windows and golden hours, when rare spawns triple.

## The world

A bright saturated daytime map built from Roblox parts: the circular Chaos Plaza hub, Meme Mountain with its giant thumbs-up statue, Brainrot Bridge over the teal river, eight individual player bases around the edges (each its own colour), hills, trees and clouds. Every character is a chunky part-built model with a glowing neon rarity aura and a floating name / rarity / $/s label.

## Controls

| Key | Action |
| --- | --- |
| WASD / arrows | Move |
| E or CATCH button | Catch the nearest brainrot |
| Shift | Dash (costs stamina) |
| INDEX button | Open the collection book |
| SHOP button | Buy base slots, rebirth |

## How it is built

- Rojo project (`default.project.json` → `game.rbxl`), plain Luau, standard Roblox APIs only, no third-party modules.
- Server owns everything that matters: catch validation (15-stud magnitude check, rejections logged), all money (a server loop over slotted characters, never client-sent), the wave clock (server heartbeat), rebirth and slot validation. One `DataManager` module centralises all player-data mutation.
- Saves use plain `DataStoreService` with a manual session lock, batched autosaves every 3 minutes plus on leave, and a retry queue that never wipes session data on failure.
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with the vendored `vendor/makefun-roblox.ts` (unchanged). It refuses a production run while `PLAY.json` still holds placeholder ids.

## Status

The place is not published yet: `PLAY.json` still holds placeholder zeros and the screenshots folder currently holds only the composed thumbnail art. The experience must be created on the Creator Dashboard, set Public, given the make.fun play code in its description, and its icon + first thumbnail uploaded — then `PLAY.json` is filled in and real gameplay screenshots from an iPhone playtest replace the placeholder set.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.
