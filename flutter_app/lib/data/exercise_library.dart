import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'exercises.dart';
import 'models.dart';

/// Rich exercise record. The curated [kExercises] provide the always-available
/// staples; the bulk of the catalogue (1,300+ movements with target/secondary
/// muscles and step-by-step instructions) is loaded lazily from the bundled
/// `assets/data/exercise_library.json`, generated from the MIT-licensed
/// exercises-dataset (https://github.com/hasaneyldrm/exercises-dataset). Only
/// the non-media fields are bundled — the dataset's GIF/thumbnail media is
/// © Gym visual and is intentionally not included.
class LibraryExercise {
  final String name;
  final String muscleGroup;
  final String category;
  final String equipment;
  final String? target;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final bool custom;

  /// `true` for the imported dataset entries, `false` for curated staples and
  /// user custom exercises — auto-generators use only the non-dataset pool.
  final bool fromDataset;

  const LibraryExercise({
    required this.name,
    required this.muscleGroup,
    required this.category,
    required this.equipment,
    this.target,
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.custom = false,
    this.fromDataset = false,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> j) => LibraryExercise(
        name: j['name'] as String,
        muscleGroup: j['muscleGroup'] as String? ?? 'full_body',
        category: j['category'] as String? ?? 'compound',
        equipment: j['equipment'] as String? ?? 'other',
        target: j['target'] as String?,
        secondaryMuscles: (j['secondaryMuscles'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        instructions: (j['instructions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        fromDataset: true,
      );

  factory LibraryExercise.fromCurated(Exercise e) => LibraryExercise(
        name: e.name,
        muscleGroup: e.muscleGroup,
        category: e.category,
        equipment: e.equipment,
      );

  factory LibraryExercise.fromCustom(CustomExercise c) => LibraryExercise(
        name: c.name,
        muscleGroup: c.muscleGroup,
        category: c.category,
        equipment: c.equipment,
        custom: true,
      );
}

/// Loads and caches the bundled exercise dataset, and builds the combined
/// library (custom + curated staples + dataset, de-duped by name).
class ExerciseLibrary {
  static List<LibraryExercise>? _dataset;
  static Future<List<LibraryExercise>>? _loading;

  /// Load the dataset once; subsequent calls return the cached list.
  static Future<List<LibraryExercise>> loadDataset() {
    if (_dataset != null) return Future.value(_dataset);
    return _loading ??= rootBundle
        .loadString('assets/data/exercise_library.json')
        .then((raw) {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();
      _dataset = list;
      return list;
    });
  }

  /// Combined library: user custom first (so overrides win), then curated
  /// staples, then the dataset — de-duped by case-insensitive name.
  static List<LibraryExercise> combined(
    List<CustomExercise> custom,
    List<LibraryExercise> dataset,
  ) {
    final seen = <String>{};
    final out = <LibraryExercise>[];
    void add(LibraryExercise e) {
      final key = e.name.toLowerCase();
      if (seen.add(key)) out.add(e);
    }

    for (final c in custom) {
      add(LibraryExercise.fromCustom(c));
    }
    for (final e in kExercises) {
      add(LibraryExercise.fromCurated(e));
    }
    for (final e in dataset) {
      add(e);
    }
    return out;
  }
}
