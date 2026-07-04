import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/programs_repo.dart';
import '../data/active_plan.dart';
import '../data/store.dart';

/// Preview + activate screen for a bundled program (Pure Bodybuilding,
/// Powerbuilding 3.0, etc). Loads the full session sequence so the user can
/// see what they're committing to before it becomes their active plan.
class ProgramDetailScreen extends StatefulWidget {
  final ProgramAsset asset;
  const ProgramDetailScreen({super.key, required this.asset});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  ActivePlan? _plan;
  bool _loading = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await loadProgramAsActivePlan(widget.asset);
    if (mounted) {
      setState(() {
        _plan = plan;
        _loading = false;
      });
    }
  }

  Future<void> _activate() async {
    setState(() => _activating = true);
    await Store.setActivePlan(_plan!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${widget.asset.name} activated — see it on your Dashboard.'),
      backgroundColor: AppColors.bgElevated,
    ));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: Text(widget.asset.name,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Text(widget.asset.description,
                          style: const TextStyle(
                              fontSize: 13.5, height: 1.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _chip(Icons.calendar_today_rounded,
                              '${widget.asset.daysPerWeek}x / week'),
                          const SizedBox(width: 8),
                          _chip(Icons.hourglass_bottom_rounded, widget.asset.durationLabel),
                          const SizedBox(width: 8),
                          _chip(Icons.list_alt_rounded, '${_plan!.sessions.length} sessions'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('SESSION PREVIEW',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      ..._plan!.sessions.take(6).toList().asMap().entries.map((entry) {
                        final s = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.bgElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('${entry.key + 1}',
                                          style: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(s.name,
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w700)),
                                    ),
                                    Text('${s.exercises.length} ex',
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.exercises.map((e) => e.name).take(4).join(' · '),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textTertiary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_plan!.sessions.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              '+ ${_plan!.sessions.length - 6} more sessions across the full program',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textTertiary)),
                        ),
                    ].animate(interval: 40.ms).fadeIn(duration: 260.ms),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _activating ? null : _activate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: Text(
                              _activating ? 'Activating…' : 'Start This Program',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
