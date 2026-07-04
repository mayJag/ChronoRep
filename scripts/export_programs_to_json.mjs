// One-off conversion: pull the structured (JSON-shaped) program data out of
// src/data/*.js and write it as plain JSON assets for the Flutter app to bundle.
import { writeFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const outDir = join(root, 'flutter_app', 'assets', 'programs');

const jobs = [
  { file: 'src/data/essentialsProgram.js', exportName: 'expert_essentials', outName: 'essentials.json' },
  { file: 'src/data/fundamentalsProgram.js', exportName: 'expert_fundamentals', outName: 'fundamentals.json' },
  { file: 'src/data/pureBodybuildingProgram.js', exportName: 'expert_pure_bodybuilding', outName: 'pure_bodybuilding.json' },
  { file: 'src/data/hybridProgram.js', exportName: 'hybridProgram', outName: 'hybrid.json' },
  { file: 'src/data/btrProgram.js', exportName: 'btrProgram', outName: 'btr_jump.json' },
  { file: 'src/data/expertPowerbuilding.js', exportName: 'expertPowerbuilding', outName: 'powerbuilding.json' },
];

for (const job of jobs) {
  const mod = await import(pathToFileURL(join(root, job.file)).href);
  const data = mod[job.exportName];
  if (!data) {
    console.error(`MISSING export ${job.exportName} in ${job.file}`);
    continue;
  }
  writeFileSync(join(outDir, job.outName), JSON.stringify(data), 'utf8');
  console.log(`wrote ${job.outName} (${JSON.stringify(data).length} bytes)`);
}
