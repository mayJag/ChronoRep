import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';
import 'calculators_screen.dart';
import 'body_screen.dart';
import 'achievements_screen.dart';
import 'goals_screen.dart';
import 'exercise_library_screen.dart';

/// The "More" hub — a grid of secondary features. Built-out entries navigate;
/// not-yet-ported ones show a short note.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem('Calculators', Icons.calculate_rounded, true,
          () => const CalculatorsScreen()),
      _MoreItem('Settings', Icons.settings_rounded, true,
          () => const SettingsScreen()),
      _MoreItem('Body Metrics', Icons.monitor_weight_rounded, true,
          () => const BodyScreen()),
      _MoreItem('Achievements', Icons.emoji_events_rounded, true,
          () => const AchievementsScreen()),
      _MoreItem('Goals', Icons.flag_rounded, true, () => const GoalsScreen()),
      _MoreItem('Exercise Library', Icons.menu_book_rounded, true,
          () => const ExerciseLibraryScreen()),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text('More',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: items
                .map((it) => _MoreTile(item: it))
                .toList()
                .animate(interval: 55.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  final String label;
  final IconData icon;
  final bool ready;
  final Widget Function()? builder;
  _MoreItem(this.label, this.icon, this.ready, this.builder);
}

class _MoreTile extends StatelessWidget {
  final _MoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        if (item.ready && item.builder != null) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => item.builder!()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item.label} — being ported next.'),
            backgroundColor: AppColors.bgElevated,
          ));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: item.ready ? AppColors.brandGradient : null,
                  color: item.ready ? null : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(item.icon,
                    size: 22,
                    color: item.ready ? Colors.white : AppColors.textSecondary),
              ),
              if (!item.ready)
                const Text('SOON',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary)),
            ],
          ),
          Text(item.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
