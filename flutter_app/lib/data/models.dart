/// Core data models — mirror the shapes used by the original IndexedDB stores
/// (workoutLogs, routines, settings) so a future migration stays faithful.
library;

class ExerciseLog {
  final String name;
  final List<SetLog> sets;

  ExerciseLog({required this.name, required this.sets});

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        name: j['name'] as String? ?? 'Exercise',
        sets: (j['sets'] as List<dynamic>? ?? [])
            .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'sets': sets.map((s) => s.toJson()).toList()};
}

class SetLog {
  final double weight;
  final int reps;
  final bool done;

  SetLog({this.weight = 0, this.reps = 0, this.done = false});

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        reps: (j['reps'] as num?)?.toInt() ?? 0,
        done: j['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'weight': weight, 'reps': reps, 'done': done};
}

class WorkoutLog {
  final String id;
  final String name;
  final String date; // yyyy-mm-dd (local)
  final int duration; // minutes
  final List<ExerciseLog> exercises;

  WorkoutLog({
    required this.id,
    required this.name,
    required this.date,
    required this.duration,
    required this.exercises,
  });

  /// Total volume = sum(weight * reps) across completed sets.
  double get volume => exercises.fold(
        0,
        (t, e) => t +
            e.sets
                .where((s) => s.done)
                .fold(0.0, (st, s) => st + s.weight * s.reps),
      );

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Workout',
        date: j['date'] as String? ?? '',
        duration: (j['duration'] as num?)?.toInt() ?? 0,
        exercises: (j['exercises'] as List<dynamic>? ?? [])
            .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        'duration': duration,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
