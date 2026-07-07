import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mini_charts.dart';
import '../data/store.dart';

/// Volume trend over recent sessions, estimated-1RM trend per exercise, and
/// lifetime totals — dependency-free charts drawn with CustomPaint.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final logs = Store.getLogs();
    final chronological = logs.reversed.toList(); // oldest first

    final recent = chronological.length > 10
        ? chronological.sublist(chronological.length - 10)
        : chronological;
    final volumes = recent.map((l) => l.volume).toList();
    final labels = recent.map((l) {
      try {
        final d = DateTime.parse(l.date);
        return '${d.month}/${d.day}';
      } catch (_) {
        return '';
      }
    }).toList();

    final exerciseNames = <String>{};
    for (final l in chronological) {
      for (final e in l.exercises) {
        exerciseNames.add(e.name);
      }
    }
    final selected = _selectedExercise ??
        (exerciseNames.isNotEmpty ? exerciseNames.first : null);

    List<double> oneRmTrend = [];
    if (selected != null) {
      for (final l in chronological) {
        for (final e in l.exercises) {
          if (e.name != selected) continue;
          double best = 0;
          for (final s in e.sets) {
            if (!s.done) continue;
            final oneRm = s.reps <= 1 ? s.weight : s.weight * (1 + s.reps / 30);
            if (oneRm > best) best = oneRm;
          }
          if (best > 0) oneRmTrend.add(best);
        }
      }
    }

    final totalVolume = logs.fold(0.0, (t, l) => t + l.volume);
    final totalSets =
        logs.fold(0, (t, l) => t + l.exercises.fold(0, (s, e) => s + e.sets.length));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          Text('Progress',
              style: AppFonts.display(28,
                  weight: FontWeight.w700, letterSpacing: -0.6)),
          const SizedBox(height: 16),

          Row(
            children: [
              _totalStat('${logs.length}', 'Workouts'),
              _totalStat(
                  totalVolume > 999
                      ? '${(totalVolume / 1000).toStringAsFixed(1)}k'
                      : totalVolume.toStringAsFixed(0),
                  'Total ${Store.weightUnit}'),
              _totalStat('$totalSets', 'Total Sets'),
            ],
          ),

          const SizedBox(height: 22),
          const Text('VOLUME — LAST 10 SESSIONS',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          GlassCard(child: BarChart(values: volumes, labels: labels)),

          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ESTIMATED 1RM TREND',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary)),
              if (exerciseNames.isNotEmpty)
                GestureDetector(
                  onTap: () => _pickExercise(context, exerciseNames.toList()),
                  child: Row(
                    children: [
                      Text(selected ?? '',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                      const Icon(Icons.expand_more_rounded,
                          size: 16, color: AppColors.accent),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GlassCard(child: LineChart(values: oneRmTrend)),
        ].animate(interval: 60.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _totalStat(String value, String label) => Expanded(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(value,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

  void _pickExercise(BuildContext context, List<String> names) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: names
              .map((n) => ListTile(
                    title: Text(n, style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      setState(() => _selectedExercise = n);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
