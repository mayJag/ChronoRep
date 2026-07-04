import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dependency-free bar chart — used for weekly volume history.
class BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  const BarChart(
      {super.key, required this.values, required this.labels, this.height = 140});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.every((v) => v == 0)) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Not enough data yet',
              style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
        ),
      );
    }
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = maxV == 0 ? 0.0 : (values[i] / maxV) * (height - 22);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: h),
                    duration: Duration(milliseconds: 500 + i * 40),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => Container(
                      height: val.clamp(3, height),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i],
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textTertiary)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dependency-free line chart with dot markers — used for 1RM trend.
class LineChart extends StatelessWidget {
  final List<double> values;
  final double height;
  const LineChart({super.key, required this.values, this.height = 140});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Log a few more sessions to see a trend',
              style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(values)),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final norm = (values[i] - minV) / range;
      final y = size.height - 14 - norm * (size.height - 24);
      return Offset(dx * i, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    // Fill under the line.
    final fillPath = Path.from(path)
      ..lineTo(pointAt(values.length - 1).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.22),
            AppColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = AppColors.brandGradient
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 4, Paint()..color = AppColors.bgPrimary);
      canvas.drawCircle(p, 3, Paint()..color = AppColors.accent);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}
