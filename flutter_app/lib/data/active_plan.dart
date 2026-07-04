import 'plan_generator.dart';

/// Unified session/plan shape used by both the generator and imported
/// programs, so the Dashboard and Active Workout screen only deal with one
/// model regardless of where the plan came from.
class ActiveExercise {
  final String name;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSec;
  final String category;
  ActiveExercise(this.name, this.muscleGroup, this.sets, this.reps,
      this.restSec, this.category);

  factory ActiveExercise.fromJson(Map<String, dynamic> j) => ActiveExercise(
        j['name'] as String,
        j['muscleGroup'] as String? ?? 'full_body',
        (j['sets'] as num?)?.toInt() ?? 3,
        j['reps'] as String? ?? '8-12',
        (j['restSec'] as num?)?.toInt() ?? 90,
        j['category'] as String? ?? 'compound',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
        'restSec': restSec,
        'category': category,
      };
}

class ActiveSession {
  final String name;
  final List<ActiveExercise> exercises;
  ActiveSession(this.name, this.exercises);

  factory ActiveSession.fromJson(Map<String, dynamic> j) => ActiveSession(
        j['name'] as String,
        (j['exercises'] as List<dynamic>)
            .map((e) => ActiveExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'exercises': exercises.map((e) => e.toJson()).toList()};
}

/// An active plan is just an ordered list of sessions the user works through
/// one at a time (weekday-anchored for generated plans, sequential for
/// imported multi-week programs) plus a pointer to "today's"/"next" session.
class ActivePlan {
  final String name;
  final String source; // 'generated' | 'imported'
  final List<ActiveSession> sessions;
  final int cursor; // index of the next session to do

  ActivePlan(this.name, this.source, this.sessions, this.cursor);

  ActiveSession? get nextSession =>
      sessions.isEmpty ? null : sessions[cursor % sessions.length];

  ActivePlan advanced() =>
      ActivePlan(name, source, sessions, (cursor + 1) % sessions.length);

  factory ActivePlan.fromJson(Map<String, dynamic> j) => ActivePlan(
        j['name'] as String,
        j['source'] as String? ?? 'generated',
        (j['sessions'] as List<dynamic>)
            .map((s) => ActiveSession.fromJson(s as Map<String, dynamic>))
            .toList(),
        (j['cursor'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'source': source,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'cursor': cursor,
      };
}

/// Turn a generator output into an ActivePlan (training days only, in weekday
/// order starting from whichever day the plan begins).
ActiveSession activeSessionFromPlanDay(PlanDay day) => ActiveSession(
      day.name,
      day.exercises
          .map((e) => ActiveExercise(
              e.name, e.muscleGroup, e.sets, e.reps, e.restSec, e.category))
          .toList(),
    );

ActivePlan planFromGenerated(GeneratedPlan plan) {
  final sessions = plan.week
      .where((d) => !d.rest)
      .map((d) => ActiveSession(
          d.name,
          d.exercises
              .map((e) => ActiveExercise(
                  e.name, e.muscleGroup, e.sets, e.reps, e.restSec, e.category))
              .toList()))
      .toList();
  return ActivePlan(plan.name, 'generated', sessions, 0);
}
