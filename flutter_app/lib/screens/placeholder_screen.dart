import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// On-brand placeholder for screens not yet ported from the web app.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String blurb;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.blurb,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.18),
                          AppColors.accentSecondary.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.borderAccent),
                    ),
                    child: Icon(icon, size: 44, color: AppColors.accent),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(),
                  const SizedBox(height: 24),
                  Text(
                    '$title coming soon',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 280,
                    child: Text(
                      blurb,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Being rebuilt in Flutter',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
