// One-off conversion: pull the exercises-dataset (MIT-licensed exercise data,
// https://github.com/hasaneyldrm/exercises-dataset) into ChronoRep's exercise
// taxonomy and write it as src/data/exerciseLibrary.json.
//
// NOTE: only the non-media fields (name, category, target muscles, equipment,
// English instructions) are imported. The dataset's thumbnail/GIF media is
// © Gym visual and requires a separate license from gymvisual.com for reuse —
// it is intentionally NOT bundled here.
//
// Usage: node scripts/import_exercises_dataset.mjs <path-to-exercises.json>
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const srcPath = process.argv[2];
if (!srcPath) {
  console.error('Usage: node scripts/import_exercises_dataset.mjs <path-to-exercises.json>');
  process.exit(1);
}

const BODY_PART_TO_MUSCLE_GROUP = {
  'upper arms': 'arms',
  'lower arms': 'arms',
  'upper legs': 'legs',
  'lower legs': 'legs',
  back: 'back',
  waist: 'core',
  chest: 'chest',
  shoulders: 'shoulders',
  cardio: 'cardio',
  neck: 'neck',
};

const EQUIPMENT_MAP = {
  'body weight': 'bodyweight',
  dumbbell: 'dumbbell',
  cable: 'cable',
  barbell: 'barbell',
  'leverage machine': 'machine',
  band: 'band',
  'smith machine': 'machine',
  kettlebell: 'kettlebell',
  weighted: 'other',
  'stability ball': 'other',
  'ez barbell': 'barbell',
  assisted: 'machine',
  'sled machine': 'machine',
  'medicine ball': 'other',
  rope: 'other',
  roller: 'other',
  'resistance band': 'band',
  'bosu ball': 'other',
  'olympic barbell': 'barbell',
  'wheel roller': 'other',
  'upper body ergometer': 'machine',
  'skierg machine': 'machine',
  hammer: 'other',
  'stationary bike': 'machine',
  tire: 'other',
  'trap bar': 'barbell',
  'elliptical machine': 'machine',
  'stepmill machine': 'machine',
};

const COMPOUND_KEYWORDS = [
  'squat', 'deadlift', 'press', 'pull-up', 'pullup', 'chin-up', 'chinup',
  'row', 'lunge', 'clean', 'snatch', 'thruster', 'dip', 'push-up', 'pushup',
  'step-up', 'stepup', 'hip thrust', 'muscle-up',
];

const ISOLATION_KEYWORDS = [
  'curl', 'extension', 'raise', 'fly', 'flye', 'kickback', 'pushdown',
  'pullover', 'crossover', 'shrug', 'crunch', 'sit-up', 'situp', 'plank',
  'adduction', 'abduction', 'lateral raise',
];

function titleCase(name) {
  return name.replace(/\b\w/g, (c) => c.toUpperCase());
}

function classifyCategory(rec) {
  const name = rec.name.toLowerCase();
  if (rec.body_part === 'cardio') return 'cardio';
  if (name.includes('stretch') || name.includes('mobility') || name.includes('foam roll')) return 'mobility';
  if (/(jump|hop|bound|plyo|skater)/.test(name)) return 'plyometric';
  if (rec.body_part === 'waist') return 'core';
  if (ISOLATION_KEYWORDS.some((k) => name.includes(k))) return 'isolation';
  if (COMPOUND_KEYWORDS.some((k) => name.includes(k))) return 'compound';
  const secondaryCount = (rec.secondary_muscles || []).length;
  return secondaryCount >= 3 ? 'compound' : 'isolation';
}

function firstSentences(text, max = 5) {
  if (!text) return [];
  return text.split(/(?<=[.!?])\s+/).filter(Boolean).slice(0, max);
}

const raw = JSON.parse(readFileSync(srcPath, 'utf8'));

const seenNames = new Set();
const library = [];
let skipped = 0;

for (const rec of raw) {
  const name = titleCase(rec.name.trim());
  const key = name.toLowerCase();
  if (seenNames.has(key)) { skipped++; continue; }
  seenNames.add(key);

  const muscleGroup = BODY_PART_TO_MUSCLE_GROUP[rec.body_part] || 'full_body';
  const equipment = EQUIPMENT_MAP[rec.equipment] || 'other';
  const category = classifyCategory(rec);
  const steps = rec.instruction_steps?.en?.length
    ? rec.instruction_steps.en
    : firstSentences(rec.instructions?.en);

  library.push({
    id: `ds-${rec.id}`,
    name,
    muscleGroup,
    category,
    equipment,
    target: rec.target || null,
    secondaryMuscles: rec.secondary_muscles || [],
    instructions: steps,
    source: 'exercises-dataset',
  });
}

library.sort((a, b) => a.name.localeCompare(b.name));

const outPath = join(root, 'src', 'data', 'exerciseLibrary.json');
writeFileSync(outPath, JSON.stringify(library), 'utf8');
console.log(`Wrote ${library.length} exercises (${skipped} duplicate names skipped) to ${outPath}`);
console.log(`File size: ${(JSON.stringify(library).length / 1e6).toFixed(2)} MB`);
