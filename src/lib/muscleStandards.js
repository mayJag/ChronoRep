/* Per-muscle-group training standards used by the plan generator and shown
   to the user so they can see *why* a plan looks the way it does.

   Sourced from NSCA Essentials of Strength Training & Conditioning and ACSM
   2026 Resistance Training guidance:
   ─ Weekly hard sets: minimum effective dose (MEV) → maximum recoverable
     volume (MRV), scaled by experience level.
   ─ Frequency: minimum times/week a muscle should be trained for the set
     range to translate into growth/strength (spreading sets thinly across
     more sessions beats cramming them into one).
   ─ Rep range: the range most of that muscle's weekly volume should sit in
     for a balanced program (strength-biased muscles skew lower, isolation-
     heavy small muscles skew higher).
   ─ compoundShare: the fraction of a muscle's weekly sets that should come
     from compound (multi-joint) movements rather than isolation work. */

export const MUSCLE_STANDARDS = {
  chest: {
    label: 'Chest', frequency: '2-3x/week', repRange: '6-15',
    weeklySets: { beginner: [8, 12], intermediate: [12, 18], advanced: [16, 24] },
    compoundShare: 0.6,
  },
  back: {
    label: 'Back', frequency: '2-3x/week', repRange: '6-15',
    weeklySets: { beginner: [10, 14], intermediate: [14, 20], advanced: [18, 26] },
    compoundShare: 0.6,
  },
  shoulders: {
    label: 'Shoulders', frequency: '2-3x/week', repRange: '8-15',
    weeklySets: { beginner: [8, 12], intermediate: [12, 18], advanced: [16, 24] },
    compoundShare: 0.4,
  },
  arms: {
    label: 'Arms', frequency: '2x/week', repRange: '8-15',
    weeklySets: { beginner: [6, 10], intermediate: [10, 16], advanced: [14, 22] },
    compoundShare: 0.3,
  },
  legs: {
    label: 'Legs', frequency: '2x/week', repRange: '6-15',
    weeklySets: { beginner: [10, 14], intermediate: [14, 20], advanced: [18, 28] },
    compoundShare: 0.6,
  },
  core: {
    label: 'Core', frequency: '2-4x/week', repRange: '10-20',
    weeklySets: { beginner: [6, 10], intermediate: [8, 14], advanced: [10, 18] },
    compoundShare: 0.2,
  },
};

// Weekly per-muscle set cap by experience — kept for the existing recovery
// guardrail in planGenerator.js (the upper bound of the ranges above).
export function weeklyCapFor(experience) {
  const exp = MUSCLE_STANDARDS.legs.weeklySets[experience] ? experience : 'intermediate';
  return Object.fromEntries(
    Object.entries(MUSCLE_STANDARDS).map(([mg, s]) => [mg, s.weeklySets[exp][1]]),
  );
}

// Classify a muscle's weekly set count against the standard range for the
// given experience level. Returns 'low' | 'in-range' | 'high', plus the range.
export function evaluateWeeklyVolume(muscleGroup, sets, experience = 'intermediate') {
  const standard = MUSCLE_STANDARDS[muscleGroup];
  if (!standard) return null;
  const exp = standard.weeklySets[experience] ? experience : 'intermediate';
  const [min, max] = standard.weeklySets[exp];
  let status = 'in-range';
  if (sets < min) status = 'low';
  else if (sets > max) status = 'high';
  return { muscleGroup, label: standard.label, sets, min, max, status, frequency: standard.frequency, repRange: standard.repRange };
}

// Given a weeklySchedule (as produced by generatePlan), compute per-muscle
// weekly set totals and their standing against MUSCLE_STANDARDS.
export function summarizeWeeklyVolume(weeklySchedule, experience = 'intermediate') {
  const totals = {};
  for (const day of Object.values(weeklySchedule)) {
    for (const ex of day.exercises || []) {
      if (!ex.muscleGroup) continue;
      totals[ex.muscleGroup] = (totals[ex.muscleGroup] || 0) + (Number(ex.sets) || 0);
    }
  }
  return Object.keys(MUSCLE_STANDARDS)
    .map((mg) => evaluateWeeklyVolume(mg, totals[mg] || 0, experience))
    .filter(Boolean);
}
