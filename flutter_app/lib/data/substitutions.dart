import 'dart:math';
import 'exercise_library.dart';

/// Exercise substitution engine (ported from the web app's `substitutions.js`).
/// Ranks alternative exercises for any exercise — curated, custom, or a
/// program's shorthand entry — against a supplied library. Metadata does most
/// of the ranking (target muscle, secondary-muscle overlap, category,
/// equipment), with a library name lookup filling in whatever the caller
/// didn't supply.

// Pseudo muscle groups that don't map 1:1 onto the library's vocabulary.
const _groupExpansion = <String, List<String>>{
  'upper_body': ['chest', 'back', 'shoulders', 'arms'],
  'full_body': ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'],
};

const _stopwords = <String>{
  'the', 'and', 'or', 'with', 'single', 'arm', 'band', 'bar', 'ez', 'to',
  'of', 'on', 'a', 'an', 'per',
};

// Shorthand/abbreviations that appear in program data but not the dataset's
// full names — normalized before tokenizing.
const _synonyms = <String, String>{
  'db': 'dumbbell',
  'bb': 'barbell',
  'ohp': 'overheadpress',
  'rdl': 'romaniandeadlift',
  'ghr': 'glutehamraise',
  'pressdown': 'pushdown',
};

final _nonAlnum = RegExp(r'[^a-z0-9\s-]');
final _splitter = RegExp(r'[\s-]+');

List<String> _tokenize(String name) {
  return name
      .toLowerCase()
      .replaceAll(_nonAlnum, ' ')
      .split(_splitter)
      .map((w) => _synonyms[w] ?? w)
      .where((w) => w.length >= 3 && !_stopwords.contains(w))
      .toList();
}

LibraryExercise? _byNameLookup(List<LibraryExercise> library, String name) {
  final key = name.trim().toLowerCase();
  for (final e in library) {
    if (e.name.toLowerCase() == key) return e;
  }
  return null;
}

// Loose match for names that aren't an exact hit — rewards token overlap but
// penalizes candidates with many extra unmatched tokens, so the most precise
// match wins over a longer name that merely shares a word.
LibraryExercise? _fuzzyLookup(List<LibraryExercise> library, String name) {
  final tokens = _tokenize(name);
  if (tokens.isEmpty) return null;
  final minOverlap = min(2, tokens.length);
  LibraryExercise? best;
  var bestScore = -1 << 30;
  for (final e in library) {
    final exTokens = _tokenize(e.name);
    final overlap = tokens.where((t) => exTokens.contains(t)).length;
    if (overlap < minOverlap) continue;
    final score = overlap * 3 - exTokens.length;
    if (score > bestScore) {
      bestScore = score;
      best = e;
    }
  }
  return best;
}

class _Ref {
  final String name;
  final List<String> groups;
  final String? category;
  final String? equipment;
  final String? target;
  final List<String> secondaryMuscles;
  _Ref(this.name, this.groups, this.category, this.equipment, this.target,
      this.secondaryMuscles);
}

_Ref _resolve(List<LibraryExercise> library, LibraryExercise exercise) {
  final match = _byNameLookup(library, exercise.name) ??
      _fuzzyLookup(library, exercise.name);
  final groupsRaw = exercise.muscleGroup.isNotEmpty
      ? exercise.muscleGroup
      : (match?.muscleGroup);
  final groups = groupsRaw != null
      ? (_groupExpansion[groupsRaw] ?? [groupsRaw])
      : <String>[];
  return _Ref(
    exercise.name,
    groups,
    exercise.category.isNotEmpty ? exercise.category : match?.category,
    exercise.equipment.isNotEmpty ? exercise.equipment : match?.equipment,
    exercise.target ?? match?.target,
    exercise.secondaryMuscles.isNotEmpty
        ? exercise.secondaryMuscles
        : (match?.secondaryMuscles ?? const []),
  );
}

double _scoreCandidate(
    LibraryExercise cand, _Ref ref, List<String> refTokens) {
  var score = 0.0;
  if (ref.target != null && cand.target != null && cand.target == ref.target) {
    score += 6;
  }
  if (ref.secondaryMuscles.isNotEmpty && cand.secondaryMuscles.isNotEmpty) {
    score += cand.secondaryMuscles
            .where((m) => ref.secondaryMuscles.contains(m))
            .length *
        2;
  }
  if (ref.category != null && cand.category == ref.category) score += 3;
  if (ref.equipment != null && cand.equipment == ref.equipment) score += 2;
  final candTokens = _tokenize(cand.name);
  score += refTokens.where((t) => candTokens.contains(t)).length * 4;
  return score;
}

bool _equipmentAllowedFor(String? pref, LibraryExercise e) {
  if (pref == null || pref == 'gym') return true;
  if (pref == 'bodyweight') return e.equipment == 'bodyweight';
  if (pref == 'dumbbell') {
    return e.equipment == 'dumbbell' || e.equipment == 'bodyweight';
  }
  return true;
}

final _rng = Random();

/// Rank substitute exercises for [exercise] against [library].
///
/// [equipment] optionally constrains the pool ('bodyweight' | 'dumbbell' |
/// 'gym'/null). Returns up to [limit] alternatives, most-relevant first.
List<LibraryExercise> getSubstitutes(
  LibraryExercise exercise,
  List<LibraryExercise> library, {
  String? equipment,
  int limit = 6,
  List<String> exclude = const [],
}) {
  if (library.isEmpty) return const [];
  final ref = _resolve(library, exercise);
  if (ref.groups.isEmpty) return const [];
  final excludeSet = {
    ref.name.toLowerCase(),
    ...exclude.map((n) => n.toLowerCase()),
  };
  final refTokens = _tokenize(ref.name);

  bool inGroup(LibraryExercise e) =>
      !excludeSet.contains(e.name.toLowerCase()) &&
      ref.groups.contains(e.muscleGroup);

  var pool = library
      .where((e) => inGroup(e) && _equipmentAllowedFor(equipment, e))
      .toList();
  // If the equipment filter wiped the pool, fall back to an unfiltered pool so
  // we still surface something rather than nothing.
  if (pool.isEmpty) pool = library.where(inGroup).toList();

  final scored = pool
      .map((e) => (
            ex: e,
            score: _scoreCandidate(e, ref, refTokens) + _rng.nextDouble() * 0.01
          ))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return scored.take(limit).map((s) => s.ex).toList();
}
