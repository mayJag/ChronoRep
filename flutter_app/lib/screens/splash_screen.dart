import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Animated launch screen shown before the app proper.
/// A glowing "chrono" ring sweeps closed around a lightning mark, the wordmark
/// reveals with a shimmer, then the whole thing cross-fades into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ring; // ring sweep + logo entrance
  late final AnimationController _pulse; // ambient glow breathing

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Hold on the finished logo briefly, then hand off to the app.
    Future.delayed(const Duration(milliseconds: 2600), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, a, b) => const HomeShell(),
      transitionsBuilder: (_, a, b, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 1.06, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  void dispose() {
    _ring.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.1,
            colors: [Color(0xFF141A2B), AppColors.bgPrimary],
            stops: [0.0, 0.75],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Brand mark ---
              AnimatedBuilder(
                animation: Listenable.merge([_ring, _pulse]),
                builder: (context, _) {
                  final sweep = Curves.easeOutCubic.transform(_ring.value);
                  final glow = 0.5 + 0.5 * _pulse.value;
                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _BrandMarkPainter(sweep: sweep, glow: glow),
                    ),
                  );
                },
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 36),

              // --- Wordmark ---
              ShaderMask(
                shaderCallback: (r) =>
                    AppColors.brandGradient.createShader(r),
                child: const Text(
                  'ChronoRep',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 600.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic)
                  .shimmer(delay: 1200.ms, duration: 1100.ms, color: Colors.white),

              const SizedBox(height: 10),

              Text(
                'TRAIN WITH PRECISION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 1100.ms, duration: 700.ms),

              const SizedBox(height: 48),

              // --- Loading shimmer bar ---
              Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .slideX(begin: -1.4, end: 2.4, duration: 1300.ms)
                  .animate()
                  .fadeIn(delay: 1300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a glowing circular ring that sweeps closed, with a lightning bolt in
/// the centre — "chrono" (time/ring) + explosive energy (bolt).
class _BrandMarkPainter extends CustomPainter {
  final double sweep; // 0..1 how much of the ring is drawn
  final double glow; // 0..1 ambient glow strength
  _BrandMarkPainter({required this.sweep, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Ambient outer glow.
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * glow + 8);
    canvas.drawCircle(center, radius, glowPaint);

    // Track ring.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.bgElevated;
    canvas.drawCircle(center, radius, track);

    // Progress ring (gradient sweep).
    final grad = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [AppColors.accent, AppColors.accentSecondary, AppColors.accent],
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = grad.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * sweep, false, ring);

    // Lightning bolt (appears as the ring nears completion).
    final boltOpacity = ((sweep - 0.45) / 0.55).clamp(0.0, 1.0);
    if (boltOpacity > 0) {
      final s = radius; // scale
      final path = Path()
        ..moveTo(center.dx + s * 0.16, center.dy - s * 0.52)
        ..lineTo(center.dx - s * 0.28, center.dy + s * 0.08)
        ..lineTo(center.dx + s * 0.02, center.dy + s * 0.08)
        ..lineTo(center.dx - s * 0.16, center.dy + s * 0.52)
        ..lineTo(center.dx + s * 0.30, center.dy - s * 0.10)
        ..lineTo(center.dx + s * 0.00, center.dy - s * 0.10)
        ..close();

      final boltGlow = Paint()
        ..color = AppColors.accentSecondary.withValues(alpha: 0.5 * boltOpacity * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, boltGlow);

      final bolt = Paint()
        ..shader = AppColors.brandGradient.createShader(rect)
        ..color = Colors.white.withValues(alpha: boltOpacity);
      canvas.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.sweep != sweep || old.glow != glow;
}
