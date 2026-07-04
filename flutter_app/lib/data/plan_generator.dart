import 'dart:math';
import 'exercises.dart';

/// Evidence-based plan generation.
///
/// Standards applied (Schoenfeld et al. hypertrophy research, ACSM & NSCA
/// position stands):
///  - Hypertrophy: each muscle trained ~2x/week, 10–20 sets/muscle/week,
///    6–15 reps, ~90s rest.
///  - Strength: main patterns 2x/week, lower volume, 3–6 reps, ~3min rest,
///    compound-priority.
///  - Fat loss / conditioning: higher reps (12–20), short rest, higher density.
///  - General fitness: balanced 8–12 reps.
/// Frequency is guaranteed by the split: 4 days → Upper/Lower (2x each),
/// 6 days → PPL×2 (2x each), 3 days → Full Body (~3x each).

enum Goal { hypertrophy, strength, powerbuilding, fatLoss, general }

extension GoalInfo on Goal {
  String get label => switch (this) {
        Goal.hypertrophy => 'Build Muscle',
        Goal.strength => 'Get Stronger',
        Goal.powerbuilding => 'Powerbuilding',
        Goal.fatLoss => 'Lean & Conditioned',
        Goal.general => 'General Fitness',
      };
  String get blurb => switch (this) {
        Goal.hypertrophy =>
          'Maximise muscle growth — every muscle hit twice a week at 10–20 sets.',
        Goal.strength =>
          'Build maximal strength on the main lifts with heavy, low-rep work.',
        Goal.powerbuilding =>
          'Heavy compounds for strength, higher-rep accessories for size.',
        Goal.fatLoss =>
          'Keep muscle while leaning out — higher reps, short rest, more density.',
        Goal.general =>
          'Balanced, sustainable full-body fitness for health and function.',
      };
}

enum Experience { beginner, intermediate, advanced }

extension ExperienceInfo on Experience {
  String get label => switch (this) {
        Experience.beginner => 'Beginner',
        Experience.intermediate => 'Intermediate',
        Experience.advanced => 'Advanced',
      };
}

class _GoalParams {
  final int setsPerExercise;
  final String reps;
  final int restSec;
  final bool compoundPriority;
  const _GoalParams(
      this.setsPerExercise, this.reps, this.restSec, this.compoundPriority);
}

_GoalParams _paramsFor(Goal g) => switch (g) {
      Goal.hypertrophy => const _GoalParams(3, '8–12', 90, false),
      Goal.strength => const _GoalParams(4, '3–6', 180, true),
      Goal.powerbuilding => const _GoalParams(4, '5–8', 150, true),
      Goal.fatLoss => const _GoalParams(3, '12–20', 45, false),
      Goal.general => const _GoalParams(3, '8–12', 75, false),
    };

/// Weekly sets-per-muscle target, by goal × experience (the science "dose").
int _weeklySetTarget(Goal g, Experience e) {
  final base = switch (g) {
    Goal.hypertrophy => 16,
    Goal.strength => 10,
    Goal.powerbuilding => 14,
    Goal.fatLoss => 12,
    Goal.general => 10,
  };
  final delta = switch (e) {
    Experience.beginner => -4,
    Experience.intermediate => 0,
    Experience.advanced => 4,
  };
  return max(6, base + delta);
}

class DayTemplate {
  final String name;
  final List<String> muscles; // muscle groups trained this day
  const DayTemplate(this.name, this.muscles);
}

class SplitChoice {
  final String label;
  final String rationale;
  final List<DayTemplate> days;
  const SplitChoice(this.label, this.rationale, this.days);
}

/// Choose a split that guarantees the science-backed frequency for the goal.
SplitChoice chooseSplit(int daysPerWeek) {
  const upper = DayTemplate('Upper Body', ['chest', 'back', 'shoulders', 'arms']);
  const lower = DayTemplate('Lower Body', ['legs', 'core']);
  const push = DayTemplate('Push', ['chest', 'shoulders', 'arms']);
  const pull = DayTemplate('Pull', ['back', 'arms']);
  const legs = DayTemplate('Legs', ['legs', 'core']);
  const full = DayTemplate('Full Body', ['legs', 'chest', 'back', 'shoulders', 'core']);

  switch (daysPerWeek) {
    case 3:
      return SplitChoice('Full Body ×3',
          '3 full-body days hit every muscle ~3×/week — ideal frequency at lower volume.',
          [full, full, full]);
    case 4:
      return SplitChoice('Upper / Lower',
          '4 days as Upper/Lower trains every muscle exactly 2×/week with a rest day between halves.',
          [upper, lower, upper, lower]);
    case 5:
      return SplitChoice('Upper / Lower / Push / Pull / Legs',
          '5 days keeps every muscle at 2×/week while adding focused push, pull and leg volume.',
          [upper, lower, push, pull, legs]);
    case 6:
      return SplitChoice('Push / Pull / Legs ×2',
          '6 days as PPL×2 trains every muscle 2×/week with the highest weekly volume.',
          [push, pull, legs, push, pull, legs]);
    default:
      return chooseSplit(daysPerWeek < 3 ? 3 : 6);
  }
}

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _daySlots = {
  3: ['mon', 'wed', 'fri'],
  4: ['mon', 'tue', 'thu', 'fri'],
  5: ['mon', 'tue', 'wed', 'thu', 'fri'],
  6: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
};

class PlanExercise {
  final String name;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSec;
  final String category;
  PlanExercise(this.name, this.muscleGroup, this.sets, this.reps, this.restSec,
      this.category);
}

class PlanDay {
  final String weekdayKey; // mon..sun
  final String name;
  final bool rest;
  final List<PlanExercise> exercises;
  PlanDay(this.weekdayKey, this.name, this.rest, this.exercises);

  int get estMinutes => exercises.fold(
      0, (t, e) => t + (e.sets * (0.6 + e.restSec / 60)).ceil() + 1);
}

class GeneratedPlan {
  final String name;
  final Goal goal;
  final Experience experience;
  final SplitChoice split;
  final List<PlanDay> week; // 7 entries mon..sun
  GeneratedPlan(this.name, this.goal, this.experience, this.split, this.week);

  /// Actual weekly sets per muscle (for the science summary UI).
  Map<String, int> get weeklySetsPerMuscle {
    final m = <String, int>{};
    for (final d in week) {
      for (final e in d.exercises) {
        m[e.muscleGroup] = (m[e.muscleGroup] ?? 0) + e.sets;
      }
    }
    return m;
  }

  /// Times per week each muscle is trained (frequency).
  Map<String, int> get weeklyFrequencyPerMuscle {
    final m = <String, int>{};
    for (final d in week) {
      final seen = <String>{};
      for (final e in d.exercises) {
        seen.add(e.muscleGroup);
      }
      for (final mg in seen) {
        m[mg] = (m[mg] ?? 0) + 1;
      }
    }
    return m;
  }
}

const muscleLabels = {
  'chest': 'Chest',
  'back': 'Back',
  'shoulders': 'Shoulders',
  'arms': 'Arms',
  'legs': 'Legs',
  'core': 'Core',
};

/// Generate a full weekly plan honouring the goal's frequency + volume science.
GeneratedPlan generatePlan({
  required Goal goal,
  required int daysPerWeek,
  required Experience experience,
  required String equipment, // 'full' | 'dumbbell' | 'bodyweight'
  int? minutesPerSession, // optional cap
  int seed = 7,
}) {
  final days = daysPerWeek.clamp(3, 6);
  final split = chooseSplit(days);
  final params = _paramsFor(goal);
  final weeklyTarget = _weeklySetTarget(goal, experience);
  final rng = Random(seed);

  // How many days does each muscle appear in? (for per-day set allotment)
  final freq = <String, int>{};
  for (final t in split.days) {
    for (final mg in t.muscles) {
      freq[mg] = (freq[mg] ?? 0) + 1;
    }
  }

  // Round-robin usage counter so exercises vary across the week.
  final used = <String, int>{};
  Exercise? bestFor(String mg, Set<String> takenToday, {bool compound = false}) {
    final pool = kExercises
        .where((e) =>
            e.muscleGroup == mg &&
            equipmentAllowed(equipment, e) &&
            !takenToday.contains(e.name) &&
            (!compound || e.category == 'compound'))
        .toList();
    if (pool.isEmpty) return null;
    pool.sort((a, b) {
      final ua = used[a.name] ?? 0, ub = used[b.name] ?? 0;
      if (ua != ub) return ua - ub; // least-used first
      // prefer compounds when goal is compound-priority
      final ca = a.category == 'compound' ? 0 : 1;
      final cb = b.category == 'compound' ? 0 : 1;
      if (params.compoundPriority && ca != cb) return ca - cb;
      return rng.nextBool() ? -1 : 1;
    });
    return pool.first;
  }

  final slots = _daySlots[days]!;
  final planDays = <PlanDay>[];
  PlanDay restDay(String k) => PlanDay(k, 'Rest Day', true, []);
  final schedule = {for (final k in _weekdayKeys) k: restDay(k)};

  for (var i = 0; i < split.days.length; i++) {
    final template = split.days[i];
    final key = slots[i];
    final takenToday = <String>{};
    final exercises = <PlanExercise>[];

    for (final mg in template.muscles) {
      // Per-day sets for this muscle = weekly target / how many days it appears.
      final perDay = (weeklyTarget / (freq[mg] ?? 1)).round().clamp(3, 12);
      // Core gets a lighter dose.
      final target = mg == 'core' ? min(perDay, 6) : perDay;

      var placed = 0;
      var wantCompoundFirst = params.compoundPriority || mg == 'legs' || mg == 'back' || mg == 'chest';
      while (placed < target) {
        final ex = bestFor(mg, takenToday, compound: wantCompoundFirst && placed == 0);
        final pick = ex ?? bestFor(mg, takenToday);
        if (pick == null) break;
        takenToday.add(pick.name);
        used[pick.name] = (used[pick.name] ?? 0) + 1;

        // Sets for this exercise: cap at goal's per-exercise sets, but don't
        // overshoot the muscle's remaining daily allotment.
        var s = params.setsPerExercise;
        if (pick.category != 'compound') s = max(2, s - (goal == Goal.strength ? 1 : 0));
        s = min(s, target - placed);
        if (s < 2) s = 2;
        exercises.add(PlanExercise(
          pick.name,
          mg,
          s,
          pick.category == 'core' ? '10–20' : params.reps,
          pick.category == 'compound' ? params.restSec : (params.restSec * 0.7).round(),
          pick.category,
        ));
        placed += s;
        wantCompoundFirst = false;
      }
    }

    // Compounds first within the day.
    exercises.sort((a, b) {
      final ca = a.category == 'compound' ? 0 : 1;
      final cb = b.category == 'compound' ? 0 : 1;
      return ca - cb;
    });

    var dayExercises = exercises;
    // Time cap: trim least-important (last) accessories to fit the budget.
    if (minutesPerSession != null) {
      dayExercises = _fitToTime(exercises, minutesPerSession);
    }

    schedule[key] = PlanDay(key, template.name, false, dayExercises);
  }

  for (final k in _weekdayKeys) {
    planDays.add(schedule[k]!);
  }

  final name = '${goal.label} · $days-Day ${split.label.split(' ').first}';
  return GeneratedPlan(name, goal, experience, split, planDays);
}

/// Trim a session's accessory work so the estimated time fits [minutes].
/// Compounds are protected; isolation/core are dropped from the end first.
List<PlanExercise> _fitToTime(List<PlanExercise> exercises, int minutes) {
  final list = [...exercises];
  int est() => list.fold(
      0, (t, e) => t + (e.sets * (0.6 + e.restSec / 60)).ceil() + 1);
  while (est() > minutes && list.length > 3) {
    // remove the last non-compound
    final idx = list.lastIndexWhere((e) => e.category != 'compound');
    if (idx == -1) break;
    list.removeAt(idx);
  }
  return list;
}

/// A single time-boxed session for the "Quick Workout" flow — the user says how
/// many minutes they have and (optionally) a focus; we fill the budget.
PlanDay generateQuickSession({
  required int minutes,
  required String equipment,
  List<String> focus = const ['chest', 'back', 'shoulders', 'arms', 'legs'],
}) {
  final used = <String>{};
  final exercises = <PlanExercise>[];

  // ~ time per exercise at 3 sets, 75s rest ≈ 5–6 min. Budget accordingly,
  // reserving a little for warm-up/transitions.
  int est() =>
      exercises.fold(0, (t, e) => t + (e.sets * (0.6 + e.restSec / 60)).ceil() + 1);

  final pools = {
    for (final mg in focus)
      mg: kExercises
          .where((e) => e.muscleGroup == mg && equipmentAllowed(equipment, e))
          .toList()
        ..sort((a, b) => a.category == 'compound' ? -1 : 1)
  };

  var mgi = 0;
  var guard = 0;
  while (est() < minutes - 4 && guard++ < 40) {
    final mg = focus[mgi % focus.length];
    mgi++;
    final pool = pools[mg]!.where((e) => !used.contains(e.name)).toList();
    if (pool.isEmpty) continue;
    final ex = pool.first;
    used.add(ex.name);
    exercises.add(PlanExercise(
      ex.name,
      mg,
      ex.category == 'compound' ? 3 : 3,
      ex.category == 'core' ? '10–20' : '8–12',
      ex.category == 'compound' ? 90 : 60,
      ex.category,
    ));
  }

  exercises.sort((a, b) => (a.category == 'compound' ? 0 : 1) -
      (b.category == 'compound' ? 0 : 1));
  return PlanDay('quick', '$minutes-Min Session', false, exercises);
}
