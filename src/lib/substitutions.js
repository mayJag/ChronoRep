// Exercise substitution engine. Ranks alternative exercises for any exercise
// object — built-in, custom, or a program's shorthand entry (e.g. "SQUAT",
// "HAM RAISE") — against the caller-supplied exercise library (typically the
// `exercises` array from useExerciseLibrary(): BASE_EXERCISES + the 1,300+
// exercises imported from exercises-dataset + any custom exercises).
//
// Program exercise objects already carry muscleGroup/equipment/category
// metadata (except pureBodybuildingProgram, whose entries use real,
// specific exercise names) so substitution works even when the exercise's
// own name doesn't literally match anything in the library — metadata does
// most of the ranking, with a library name lookup filling in whatever the
// caller didn't supply (target muscle, secondary muscles, etc).

// Pseudo muscle groups used by some program day/exercise definitions that
// don't map 1:1 onto the library's muscleGroup vocabulary.
const GROUP_EXPANSION = {
  upper_body: ['chest', 'back', 'shoulders', 'arms'],
  full_body: ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'],
};

const STOPWORDS = new Set([
  'the', 'and', 'or', 'with', 'single', 'arm', 'band', 'bar', 'ez', 'to',
  'of', 'on', 'a', 'an', 'per',
]);

// Common shorthand/abbreviations that appear in program data but not the
// dataset's full exercise names — normalized before tokenizing so e.g. "DB
// Press" still overlaps with "Dumbbell Press".
const SYNONYMS = {
  db: 'dumbbell',
  bb: 'barbell',
  ohp: 'overheadpress',
  rdl: 'romaniandeadlift',
  ghr: 'glutehamraise',
  pressdown: 'pushdown',
};

function tokenize(name) {
  return (name || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/[\s-]+/)
    .map((w) => SYNONYMS[w] || w)
    .filter((w) => w.length >= 3 && !STOPWORDS.has(w));
}

function byNameLookup(library, name) {
  const key = name.trim().toLowerCase();
  return library.find((e) => e.name.toLowerCase() === key);
}

// Loose match for names that aren't an exact hit, e.g. "Bench Press" should
// still resolve close to "Barbell Bench Press" rather than some unrelated
// exercise that merely shares one word. Rewards token overlap but penalizes
// candidates with lots of extra, unmatched tokens so the most precise match
// wins over a longer name that happens to share the same word count.
function fuzzyLookup(library, name) {
  const tokens = tokenize(name);
  if (!tokens.length) return null;
  const minOverlap = Math.min(2, tokens.length);
  let best = null;
  let bestScore = -Infinity;
  for (const ex of library) {
    const exTokens = tokenize(ex.name);
    const overlap = tokens.filter((t) => exTokens.includes(t)).length;
    if (overlap < minOverlap) continue;
    const score = overlap * 3 - exTokens.length;
    if (score > bestScore) {
      bestScore = score;
      best = ex;
    }
  }
  return best;
}

// Resolve as much identity info as possible: explicit fields on the
// exercise object win; anything missing is filled in via a library lookup.
function resolve(library, exercise) {
  const name = exercise.name || '';
  const match = byNameLookup(library, name) || fuzzyLookup(library, name);
  const groupsRaw = exercise.muscleGroup || match?.muscleGroup || null;
  const groups = groupsRaw
    ? (GROUP_EXPANSION[groupsRaw] || [groupsRaw])
    : (match ? [match.muscleGroup] : []);
  return {
    name,
    groups,
    category: exercise.category || match?.category || null,
    equipment: exercise.equipment || match?.equipment || null,
    target: exercise.target || match?.target || null,
    secondaryMuscles: exercise.secondaryMuscles || match?.secondaryMuscles || [],
  };
}

function scoreCandidate(cand, ref, refTokens) {
  let score = 0;
  if (ref.target && cand.target && cand.target === ref.target) score += 6;
  if (ref.secondaryMuscles?.length && cand.secondaryMuscles?.length) {
    score += cand.secondaryMuscles.filter((m) => ref.secondaryMuscles.includes(m)).length * 2;
  }
  if (ref.category && cand.category === ref.category) score += 3;
  if (ref.equipment && cand.equipment === ref.equipment) score += 2;
  const candTokens = tokenize(cand.name);
  score += refTokens.filter((t) => candTokens.includes(t)).length * 4;
  return score;
}

function equipmentAllowedFor(equipPref, ex) {
  if (!equipPref || equipPref === 'gym') return true;
  if (equipPref === 'bodyweight') return ex.equipment === 'bodyweight';
  if (equipPref === 'dumbbell') return ['dumbbell', 'bodyweight'].includes(ex.equipment);
  return true;
}

/**
 * Rank substitute exercises for `exercise` (any object with at least a
 * `name`; muscleGroup/equipment/category/target are used when present and
 * otherwise inferred via a library name lookup) against `library` (an array
 * of exercise objects, e.g. the `exercises` array from useExerciseLibrary()).
 *
 * @param {object} exercise - e.g. { name, muscleGroup, equipment, category }
 * @param {Array<object>} library - exercise pool to search, e.g. useExerciseLibrary().exercises
 * @param {object} [opts]
 * @param {string|null} [opts.equipment] - 'bodyweight' | 'dumbbell' | 'gym' (or null/'gym' = no constraint)
 * @param {number} [opts.limit]
 * @param {string[]} [opts.exclude] - additional exercise names to exclude (already-tried substitutes)
 * @returns {Array<{name, muscleGroup, equipment, category, target}>}
 */
export function getSubstitutes(exercise, library, { equipment = null, limit = 6, exclude = [] } = {}) {
  if (!library?.length) return [];
  const ref = resolve(library, exercise);
  if (!ref.groups.length) return [];
  const refName = ref.name.toLowerCase();
  const excludeSet = new Set([refName, ...exclude.map((n) => n.toLowerCase())]);
  const refTokens = tokenize(ref.name);

  const inGroup = (ex) => !excludeSet.has(ex.name.toLowerCase()) && ref.groups.includes(ex.muscleGroup);

  let pool = library.filter((ex) => inGroup(ex) && equipmentAllowedFor(equipment, ex));
  // If the equipment filter wiped the pool (the exercise itself needs
  // equipment the user doesn't have), fall back to an unfiltered pool so we
  // still surface something rather than nothing.
  if (!pool.length) pool = library.filter(inGroup);

  return pool
    .map((ex) => ({ ex, score: scoreCandidate(ex, ref, refTokens) + Math.random() * 0.01 }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ ex }) => ({
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      equipment: ex.equipment,
      category: ex.category,
      target: ex.target || null,
    }));
}
