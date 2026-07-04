import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Lightweight persistence layer backed by shared_preferences (JSON blobs).
/// Mirrors the CRUD surface of the original web `db.js` closely enough that a
/// later swap to sqflite/hive is a drop-in.
class Store {
  static const _kLogs = 'workoutLogs';
  static const _kUserName = 'userName';
  static const _kWeightUnit = 'weightUnit';

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
}
