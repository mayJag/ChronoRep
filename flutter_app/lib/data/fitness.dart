import 'models.dart';

/// Derived-stat helpers ported from the web app's `lib/fitness.js`.

String localDateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class WeekStats {
  final int count; // sessions this calendar week
  final int daysTrained; // distinct days
  final double volume;
  final DateTime weekStart;
  final Set<String> trainedDates;
  WeekStats(this.count, this.daysTrained, this.volume, this.weekStart,
      this.trainedDates);
}

/// Monday-anchored calendar week stats.
WeekStats weeklyStats(List<WorkoutLog> logs, DateTime now) {
  final weekday = now.weekday; // Mon=1..Sun=7
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: weekday - 1));
  final start = localDateStr(monday);
  final end = localDateStr(monday.add(const Duration(days: 6)));

  final inWeek =
      logs.where((l) => l.date.compareTo(start) >= 0 && l.date.compareTo(end) <= 0);
  final dates = <String>{};
  double vol = 0;
  int count = 0;
  for (final l in inWeek) {
    count++;
    dates.add(l.date);
    vol += l.volume;
  }
  return WeekStats(count, dates.length, vol, monday, dates);
}

/// Consecutive-day streak counting back from today (or yesterday).
int computeStreak(List<WorkoutLog> logs) {
  if (logs.isEmpty) return 0;
  final days = logs.map((l) => l.date).toSet();
  var streak = 0;
  var cursor = DateTime.now();
  // Allow the streak to be "alive" if trained today OR yesterday.
  if (!days.contains(localDateStr(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(localDateStr(cursor))) return 0;
  }
  while (days.contains(localDateStr(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

class Level {
  final int level;
  final String title;
  final double progressPct; // 0..100 to next level
  Level(this.level, this.title, this.progressPct);
}

const _titles = [
  'Novice', 'Beginner', 'Trainee', 'Athlete', 'Competitor',
  'Elite', 'Veteran', 'Champion', 'Master', 'Legend',
];

/// XP model: 10 per session + 5 per PR (kept simple & faithful to the spirit).
int computeXP(List<WorkoutLog> logs, int prCount) =>
    logs.length * 10 + prCount * 5;

Level levelFromXP(int xp) {
  // Each level needs progressively more XP: level n requires 50*n cumulative.
  var level = 1;
  var needed = 50;
  var remaining = xp;
  while (remaining >= needed) {
    remaining -= needed;
    level++;
    needed = 50 * level;
  }
  final pct = needed == 0 ? 0.0 : (remaining / needed) * 100;
  final title = _titles[(level - 1).clamp(0, _titles.length - 1)];
  return Level(level, title, pct.clamp(0, 100));
}
