import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'active_plan.dart';
import 'exercises.dart' show kExercises;

/// Loads the bundled, evidence-based programs (ported from the original
/// Jeff-Nippard-inspired program data) and normalises their differing JSON
/// shapes — some use `weeks[]`, the jump program uses `phases[].weeks[]`,
/// rest is written as "60s" / "3-4 min" / "1 min", set counts appear as
/// `workingSets` or `sets` — into the app's unified [ActivePlan] model.
class ProgramAsset {
  final String file;
  final String id;
  final String name;
  final String description;
  final int daysPerWeek;
  final String durationLabel;
  const ProgramAsset(this.file, this.id, this.name, this.description,
      this.daysPerWeek, this.durationLabel);
}

const List<ProgramAsset> kProgramCatalog = [
  ProgramAsset(
    'assets/programs/pure_bodybuilding.json',
    'expert-pure-bodybuilding',
    'Pure Bodybuilding',
    'Physique-focused hypertrophy split — every muscle trained twice weekly at high volume.',
    5,
    '10 weeks',
  ),
  ProgramAsset(
    'assets/programs/powerbuilding.json',
    'expert-powerbuilding',
    'Powerbuilding 3.0',
    'Heavy main lifts for strength paired with hypertrophy accessories for size.',
    5,
    '12 weeks',
  ),
  ProgramAsset(
    'assets/programs/essentials.json',
    'expert-essentials',
    'The Essentials',
    'Minimalist full-body training built around the highest-return lifts.',
    3,
    '12 weeks',
  ),
  ProgramAsset(
    'assets/programs/fundamentals.json',
    'expert-fundamentals',
    'Fundamentals Hypertrophy',
    'A science-based on-ramp for newer lifters — technique first, then load.',
    4,
    '~8 weeks',
  ),
  ProgramAsset(
    'assets/programs/hybrid.json',
    'hybrid-powerbuilding-jump',
    'Hybrid Powerbuilding + Jump',
    'Combines heavy powerlifting-style work with vertical jump training.',
    6,
    '4 weeks',
  ),
  ProgramAsset(
    'assets/programs/btr_jump.json',
    'beyond-the-rim',
    'Beyond The Rim — Vertical Jump',
    'A dedicated bodyweight vertical jump program, phased for knee health and power.',
    7,
    '20+ weeks',
  ),
];

int _parseRestSeconds(dynamic rest) {
  if (rest == null) return 90;
  final s = rest.toString().toLowerCase();
  final match = RegExp(r'(\d+)').firstMatch(s);
  final n = match != null ? int.parse(match.group(1)!) : 90;
  if (s.contains('min')) return n * 60;
  return n; // assume seconds ("60s", "90s")
}

int _parseSets(Map<String, dynamic> ex) {
  final working = ex['workingSets'] ?? ex['sets'];
  if (working == null) return 3;
  if (working is num) return working.toInt();
  return int.tryParse(working.toString()) ?? 3;
}

final _libByName = {
  for (final e in kExercises) e.name.toLowerCase(): e,
};

ActiveExercise _parseExercise(Map<String, dynamic> ex) {
  final name = ex['name'] as String? ?? 'Exercise';
  final lib = _libByName[name.toLowerCase()];
  return ActiveExercise(
    name,
    ex['muscleGroup'] as String? ?? lib?.muscleGroup ?? 'full_body',
    _parseSets(ex),
    ex['reps']?.toString() ?? '8-12',
    _parseRestSeconds(ex['rest']),
    ex['category'] as String? ?? lib?.category ?? 'compound',
  );
}

ActiveSession? _parseDay(Map<String, dynamic> day) {
  final exercisesJson = day['exercises'] as List<dynamic>? ?? [];
  if (day['type'] == 'rest' || exercisesJson.isEmpty) return null;
  final exercises =
      exercisesJson.map((e) => _parseExercise(e as Map<String, dynamic>)).toList();
  return ActiveSession(day['name'] as String? ?? 'Session', exercises);
}

/// Flattens every week (or phase→week, for the jump program) in program
/// order into one sequential list of training sessions.
List<ActiveSession> _flattenSessions(Map<String, dynamic> data) {
  final sessions = <ActiveSession>[];

  void consumeWeeks(List<dynamic> weeks) {
    for (final w in weeks) {
      final week = w as Map<String, dynamic>;
      final days = week['days'] as List<dynamic>? ?? [];
      for (final d in days) {
        final s = _parseDay(d as Map<String, dynamic>);
        if (s != null) sessions.add(s);
      }
    }
  }

  if (data['weeks'] is List) {
    consumeWeeks(data['weeks'] as List<dynamic>);
  } else if (data['phases'] is List) {
    for (final p in data['phases'] as List<dynamic>) {
      final phase = p as Map<String, dynamic>;
      if (phase['weeks'] is List) consumeWeeks(phase['weeks'] as List<dynamic>);
    }
  }
  return sessions;
}

Future<Map<String, dynamic>> _loadJson(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Parses a bundled program asset into an [ActivePlan] ready to activate.
Future<ActivePlan> loadProgramAsActivePlan(ProgramAsset asset) async {
  final data = await _loadJson(asset.file);
  final sessions = _flattenSessions(data);
  return ActivePlan(asset.name, 'imported', sessions, 0);
}
