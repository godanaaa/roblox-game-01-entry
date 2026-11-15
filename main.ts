// Coin Rush Obby: a 3D Roblox platformer for make.fun's roblox-game-01.
// The game is this directory's Rojo project, built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`. This program hands it
// in: it copies game.rbxl, src/, screenshots/ and PLAY.json from beside this
// file to /output and writes /output/dossier.json, the summary the judge
// reads, with the vendored make.fun library.
//
// The game: sprint across floating platforms, collect 10 spinning coins,
// ride two moving platforms, dodge the lava below, hit the blue checkpoint
// pads, and reach the golden finish pad. The server owns every rule; the
// client draws the start screen, the HUD and the win screen.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader's /output exists; a local run's stand-in may not, so make it.
mkdirSync(out, { recursive: true });

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
const dossierPath = join(out, 'dossier.json');
writeFileSync(
  dossierPath,
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
console.log(`Coin Rush Obby: wrote ${dossierPath}`);
