import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'program_builder_screen.dart';
import 'quick_workout_screen.dart';

/// Plan tab: entry points to the science-based plan builder, the time-boxed
/// quick workout, and featured evidence-based programs.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text('Plan',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 4),
          const Text('Train by the science, not by guesswork.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          _BigActionCard(
            title: 'Build a Science-Based Plan',
            subtitle:
                'Pick your goal — we build a weekly split that hits every muscle at the right frequency and volume.',
            icon: Icons.auto_awesome_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProgramBuilderScreen())),
          ),
          const SizedBox(height: 14),
          _BigActionCard(
            title: 'Quick Workout',
            subtitle:
                "Only got 30 minutes? Tell us how long you have and we'll size the session to fit.",
            icon: Icons.timer_rounded,
            accent: false,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const QuickWorkoutScreen())),
          ),

          const SizedBox(height: 26),
          const Text('FEATURED PROGRAMS',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ..._featured.map((p) => _ProgramCard(program: p)),
        ]
            .animate(interval: 60.ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _FeaturedProgram {
  final String name;
  final String meta;
  final String desc;
  const _FeaturedProgram(this.name, this.meta, this.desc);
}

const _featured = [
  _FeaturedProgram('Pure Bodybuilding', 'Hypertrophy · 5 days',
      'Physique-focused split with each muscle trained twice weekly at high volume.'),
  _FeaturedProgram('Powerbuilding 3.0', 'Strength + Size · 5 days',
      'Heavy main lifts paired with hypertrophy accessories for strength and mass.'),
  _FeaturedProgram('The Essentials', 'Minimalist · 3 days',
      'Time-efficient full-body training built around the highest-return lifts.'),
  _FeaturedProgram('Fundamentals Hypertrophy', 'Beginner · 3 days',
      'A science-based on-ramp for newer lifters focused on technique and progression.'),
];

class _ProgramCard extends StatelessWidget {
  final _FeaturedProgram program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${program.name} — full program import coming next.'),
            backgroundColor: AppColors.bgElevated,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(program.name,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(program.meta,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(program.desc,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.4, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;
  const _BigActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      accent: accent,
      gradient: accent
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.16),
                AppColors.accentSecondary.withValues(alpha: 0.06),
              ],
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: accent ? AppColors.brandGradient : null,
              color: accent ? null : AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon,
                size: 26, color: accent ? Colors.white : AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.4, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
