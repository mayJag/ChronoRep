import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mini_charts.dart';
import '../data/store.dart';
import '../data/models.dart';
import '../data/fitness.dart';

/// Bodyweight logging with a trend chart. One entry per calendar day.
class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null || w <= 0) return;
    await Store.saveBodyMetric(
        BodyMetric(date: localDateStr(DateTime.now()), weight: w));
    _weightCtrl.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final metrics = Store.getBodyMetrics();
    final unit = Store.weightUnit;
    final trend = metrics.map((m) => m.weight).toList();
    final latest = metrics.isNotEmpty ? metrics.last : null;
    final change = metrics.length >= 2
        ? metrics.last.weight - metrics[metrics.length - 2].weight
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Body Metrics',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    cursorColor: AppColors.accent,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Today's weight",
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      suffixText: unit,
                      filled: true,
                      fillColor: AppColors.bgInput,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _log,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (latest != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text('${latest.weight.toStringAsFixed(1)} $unit',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('CURRENT',
                            style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text(
                            change == null
                                ? '—'
                                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} $unit',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: change == null
                                    ? AppColors.textPrimary
                                    : (change > 0 ? AppColors.warning : AppColors.success))),
                        const SizedBox(height: 4),
                        const Text('CHANGE',
                            style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          const Text('TREND',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          GlassCard(child: LineChart(values: trend)),
        ].animate(interval: 60.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
