import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/store.dart';
import '../data/fitness.dart';

class _Badge {
  final String label;
  final IconData icon;
  final bool earned;
  const _Badge(this.label, this.icon, this.earned);
}

/// XP/level progress plus a badge grid, entirely derived from workout logs —
/// no separate achievement storage needed.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = Store.getLogs();
    final level = levelFromXP(computeXP(logs, 0));
    final streak = computeStreak(logs);
    final count = logs.length;

    final badges = [
      _Badge('First Workout', Icons.emoji_events_rounded, count >= 1),
      _Badge('10 Workouts', Icons.military_tech_rounded, count >= 10),
      _Badge('50 Workouts', Icons.workspace_premium_rounded, count >= 50),
      _Badge('100 Workouts', Icons.diamond_rounded, count >= 100),
      _Badge('3-Day Streak', Icons.local_fire_department_rounded, streak >= 3),
      _Badge('7-Day Streak', Icons.whatshot_rounded, streak >= 7),
      _Badge('30-Day Streak', Icons.bolt_rounded, streak >= 30),
      _Badge('Level 5', Icons.star_rounded, level.level >= 5),
      _Badge('Level 10', Icons.stars_rounded, level.level >= 10),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          GlassCard(
            accent: true,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${level.level}',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(level.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: (level.progressPct / 100).clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: AppColors.bgElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${level.progressPct.toStringAsFixed(0)}% to Level ${level.level + 1}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('BADGES',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.86,
            children: badges
                .map((b) => _BadgeTile(badge: b))
                .toList()
                .animate(interval: 50.ms)
                .fadeIn(duration: 280.ms)
                .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      accent: badge.earned,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: badge.earned ? AppColors.brandGradient : null,
              color: badge.earned ? null : AppColors.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(badge.icon,
                size: 22,
                color: badge.earned ? Colors.white : AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: badge.earned ? AppColors.textPrimary : AppColors.textTertiary)),
        ],
      ),
    );
  }
}
