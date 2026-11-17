// Brainrot Catch — make.fun roblox-brainrot-01 entrypoint (Node 22, stdlib only).
//
// The game is the Rojo project in this directory: `rojo build
// default.project.json --output game.rbxl` turns src/ into game.rbxl, and this
// program hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json
// from beside this file to /output and writes /output/dossier.json, the
// summary the judge reads, with the vendored make.fun library.
//
// PLAY.json guard: the entry is not submittable while PLAY.json still holds
// the starter's placeholder zeros (no published place yet). A production run
// — MAKEFUN_OUTPUT_DIR unset, writing to /output — refuses to produce a
// dossier from placeholder ids and exits 1 with a loud error, so nobody
// submits an unfinished entry. A local verification run (MAKEFUN_OUTPUT_DIR
// set, e.g. `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`) prints
// the same warning to stderr but still writes the output, so the build can
// be checked before the place exists.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: the grader fails an entry whose output holds
// any other, so src/ and screenshots/ are copied without any name that
// starts with a dot, at any depth.

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';
const isProductionRun = process.env.MAKEFUN_OUTPUT_DIR === undefined;

// The guard: refuse a production dossier while PLAY.json names no place.
const playLink = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8'));
const playLinkIsPlaceholder =
  playLink.place_id === 0 || playLink.universe_id === 0 || typeof playLink.url !== 'string' || !playLink.url.includes('/games/') || playLink.url.endsWith('/games/0');
if (playLinkIsPlaceholder) {
  const warning = [
    'BRAINROT CATCH: PLAY.json still holds placeholder ids (place_id 0, universe_id 0).',
    'No published place exists yet — publish the experience, set it Public, and',
    'fill in PLAY.json with its real play link before submitting.',
  ].join('\n');
  console.error(warning);
  if (isProductionRun) {
    console.error('Refusing to write a production dossier from placeholder ids.');
    process.exit(1);
  }
}

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// Second line of defence for the dotted-name rule: walk what was just
// copied and fail loudly if any name starting with a dot slipped through.
let copiedFiles = 0;
const walkOutput = (dir: string): void => {
  for (const name of readdirSync(dir)) {
    if (name.startsWith('.')) {
      console.error(`BRAINROT CATCH: dotted name in output: ${join(dir, name)} — refusing to hand in.`);
      process.exit(1);
    }
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walkOutput(full);
    else copiedFiles += 1;
  }
};
walkOutput(out);

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);

console.log(`Brainrot Catch: wrote ${join(out, 'dossier.json')} (${copiedFiles} files copied before the dossier)`);
