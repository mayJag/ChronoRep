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

class BodyMetric {
  final String date; // yyyy-mm-dd, one entry per day
  final double weight;
  final double? bodyFat;

  BodyMetric({required this.date, required this.weight, this.bodyFat});

  factory BodyMetric.fromJson(Map<String, dynamic> j) => BodyMetric(
        date: j['date'] as String,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        bodyFat: (j['bodyFat'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {'date': date, 'weight': weight, 'bodyFat': bodyFat};
}

enum GoalType { liftWeight, bodyweight }

class UserGoal {
  final String id;
  final GoalType type;
  final String label; // e.g. exercise name for liftWeight
  final double target;
  final double startValue;
  final String? targetDate;

  UserGoal({
    required this.id,
    required this.type,
    required this.label,
    required this.target,
    required this.startValue,
    this.targetDate,
  });

  factory UserGoal.fromJson(Map<String, dynamic> j) => UserGoal(
        id: j['id'] as String,
        type: GoalType.values.byName(j['type'] as String),
        label: j['label'] as String,
        target: (j['target'] as num).toDouble(),
        startValue: (j['startValue'] as num?)?.toDouble() ?? 0,
        targetDate: j['targetDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'target': target,
        'startValue': startValue,
        'targetDate': targetDate,
      };
}

class CustomExercise {
  final String name;
  final String muscleGroup;
  final String category;
  final String equipment;

  CustomExercise(
      {required this.name,
      required this.muscleGroup,
      required this.category,
      required this.equipment});

  factory CustomExercise.fromJson(Map<String, dynamic> j) => CustomExercise(
        name: j['name'] as String,
        muscleGroup: j['muscleGroup'] as String,
        category: j['category'] as String,
        equipment: j['equipment'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'muscleGroup': muscleGroup,
        'category': category,
        'equipment': equipment,
      };
}
