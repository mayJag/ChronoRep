import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'active_plan.dart';

/// Lightweight persistence layer backed by shared_preferences (JSON blobs).
/// Mirrors the CRUD surface of the original web `db.js` closely enough that a
/// later swap to sqflite/hive is a drop-in.
class Store {
  static const _kLogs = 'workoutLogs';
  static const _kUserName = 'userName';
  static const _kWeightUnit = 'weightUnit';
  static const _kActivePlan = 'activePlan';
  static const _kBodyMetrics = 'bodyMetrics';
  static const _kGoals = 'goals';
  static const _kCustomExercises = 'customExercises';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Settings ---
  static String get userName => _prefs?.getString(_kUserName) ?? '';
  static Future<void> setUserName(String v) async =>
      _prefs?.setString(_kUserName, v);

  static String get weightUnit => _prefs?.getString(_kWeightUnit) ?? 'kg';
  static Future<void> setWeightUnit(String v) async =>
      _prefs?.setString(_kWeightUnit, v);

  // --- Workout logs ---
  static List<WorkoutLog> getLogs() {
    final raw = _prefs?.getString(_kLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final logs = list
          .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
      logs.sort((a, b) => b.date.compareTo(a.date)); // newest first
      return logs;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLog(WorkoutLog log) async {
    final logs = getLogs()..removeWhere((l) => l.id == log.id);
    logs.add(log);
    await _prefs?.setString(
        _kLogs, jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  static Future<void> deleteLog(String id) async {
    final logs = getLogs()..removeWhere((l) => l.id == id);
    await _prefs?.setString(
        _kLogs, jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  /// Wipe all logged sessions but keep profile, plan, goals, and body metrics.
  static Future<void> clearHistory() async => _prefs?.remove(_kLogs);

  /// Reset the app to a first-launch state — removes every stored key
  /// (logs, plan, goals, body metrics, custom exercises, and preferences).
  static Future<void> resetAll() async {
    for (final k in const [
      _kLogs,
      _kUserName,
      _kWeightUnit,
      _kActivePlan,
      _kBodyMetrics,
      _kGoals,
      _kCustomExercises,
    ]) {
      await _prefs?.remove(k);
    }
  }

  /// Best (weight, reps) ever logged for an exercise, and the date it happened
  /// — used for "previous performance" tap-to-fill and progressive-overload
  /// suggestions.
  static (double, int, String)? bestSetFor(String exerciseName) {
    double bestWeight = -1;
    int bestReps = 0;
    String bestDate = '';
    for (final log in getLogs()) {
      for (final ex in log.exercises) {
        if (ex.name != exerciseName) continue;
        for (final s in ex.sets) {
          if (!s.done) continue;
          if (s.weight > bestWeight ||
              (s.weight == bestWeight && s.reps > bestReps)) {
            bestWeight = s.weight;
            bestReps = s.reps;
            bestDate = log.date;
          }
        }
      }
    }
    return bestWeight < 0 ? null : (bestWeight, bestReps, bestDate);
  }

  /// Most recent completed sets logged for an exercise (any session),
  /// used to pre-fill "previous performance" in the active workout screen.
  static List<SetLog> lastSetsFor(String exerciseName) {
    for (final log in getLogs()) {
      for (final ex in log.exercises) {
        if (ex.name == exerciseName && ex.sets.any((s) => s.done)) {
          return ex.sets.where((s) => s.done).toList();
        }
      }
    }
    return [];
  }

  // --- Active plan ---
  static ActivePlan? getActivePlan() {
    final raw = _prefs?.getString(_kActivePlan);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ActivePlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setActivePlan(ActivePlan plan) async =>
      _prefs?.setString(_kActivePlan, jsonEncode(plan.toJson()));

  static Future<void> clearActivePlan() async =>
      _prefs?.remove(_kActivePlan);

  static Future<void> advancePlanCursor() async {
    final plan = getActivePlan();
    if (plan != null) await setActivePlan(plan.advanced());
  }

  // --- Body metrics ---
  static List<BodyMetric> getBodyMetrics() {
    final raw = _prefs?.getString(_kBodyMetrics);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final metrics = list
          .map((e) => BodyMetric.fromJson(e as Map<String, dynamic>))
          .toList();
      metrics.sort((a, b) => a.date.compareTo(b.date)); // oldest first
      return metrics;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBodyMetric(BodyMetric m) async {
    final metrics = getBodyMetrics()..removeWhere((x) => x.date == m.date);
    metrics.add(m);
    await _prefs?.setString(
        _kBodyMetrics, jsonEncode(metrics.map((x) => x.toJson()).toList()));
  }

  // --- Goals ---
  static List<UserGoal> getGoals() {
    final raw = _prefs?.getString(_kGoals);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => UserGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGoal(UserGoal g) async {
    final goals = getGoals()..removeWhere((x) => x.id == g.id);
    goals.add(g);
    await _prefs?.setString(
        _kGoals, jsonEncode(goals.map((x) => x.toJson()).toList()));
  }

  static Future<void> deleteGoal(String id) async {
    final goals = getGoals()..removeWhere((x) => x.id == id);
    await _prefs?.setString(
        _kGoals, jsonEncode(goals.map((x) => x.toJson()).toList()));
  }

  // --- Custom exercises ---
  static List<CustomExercise> getCustomExercises() {
    final raw = _prefs?.getString(_kCustomExercises);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomExercise(CustomExercise e) async {
    final list = getCustomExercises()
      ..removeWhere((x) => x.name.toLowerCase() == e.name.toLowerCase());
    list.add(e);
    await _prefs?.setString(
        _kCustomExercises, jsonEncode(list.map((x) => x.toJson()).toList()));
  }
}

String genId() =>
    '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecondsSinceEpoch % 997)}';
