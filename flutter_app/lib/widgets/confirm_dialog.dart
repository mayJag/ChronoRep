import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Visual intent of a confirmation.
///  - [danger]  red icon chip + red action button (delete / quit / clear / reset)
///  - [neutral] violet icon chip + violet action button (heads-up, non-destructive)
enum ConfirmVariant { danger, neutral }

/// A single reusable confirmation modal: bottom-centered card, spring entrance,
/// backdrop blur, icon chip, title, one-sentence consequence, and a
/// Cancel + verb action pair. Returns `true` only if the user taps the action.
///
/// Use [ConfirmDialog.show] directly, or the [danger]/[neutral] shorthands.
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    ConfirmVariant variant = ConfirmVariant.danger,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final t = anim.value.clamp(0.0, 1.0);
        final spring = CurvedAnimation(
          parent: anim,
          curve: AppMotion.spring,
          reverseCurve: Curves.easeInCubic,
        ).value;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
          child: Opacity(
            opacity: t,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Transform.translate(
                    offset: Offset(0, 44 * (1 - spring)),
                    child: Transform.scale(
                      scale: 0.94 + 0.06 * spring,
                      child: _Card(
                        icon: icon,
                        title: title,
                        message: message,
                        confirmLabel: confirmLabel,
                        cancelLabel: cancelLabel,
                        variant: variant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  static Future<bool> danger(
    BuildContext context, {
    IconData icon = Icons.warning_amber_rounded,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
  }) =>
      show(
        context,
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: ConfirmVariant.danger,
      );

  static Future<bool> neutral(
    BuildContext context, {
    IconData icon = Icons.info_outline_rounded,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
  }) =>
      show(
        context,
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: ConfirmVariant.neutral,
      );
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmVariant variant;

  const _Card({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = variant == ConfirmVariant.danger;
    final accent = isDanger ? AppColors.danger : AppColors.accent;
    final glow = isDanger ? AppColors.dangerGlow : AppColors.accentGlow;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: glow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppFonts.display(19, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _Button(
                  label: cancelLabel,
                  onTap: () => Navigator.of(context).pop(false),
                  filled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Button(
                  label: confirmLabel,
                  onTap: () => Navigator.of(context).pop(true),
                  filled: true,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  const _Button({
    required this.label,
    required this.onTap,
    required this.filled,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? (color ?? AppColors.accent) : AppColors.bgElevated,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
