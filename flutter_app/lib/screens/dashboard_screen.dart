import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/store.dart';
import '../data/models.dart';
import '../data/fitness.dart';
import '../data/active_plan.dart';
import 'quick_workout_screen.dart';
import 'active_workout_screen.dart';

const _quotes = [
  "The only bad workout is the one that didn't happen.",
  "It never gets easier, you just get better.",
  "Success isn't always about greatness. It's about consistency.",
  "What hurts today makes you stronger tomorrow.",
  "Your body can stand almost anything. It's your mind you must convince.",
  "We are what we repeatedly do. Excellence is a habit. — Aristotle",
  "Don't count the days, make the days count. — Muhammad Ali",
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<WorkoutLog> _logs = [];
  late WeekStats _week;
  int _streak = 0;
  late Level _level;
  ActivePlan? _activePlan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = Store.getLogs();
    final now = DateTime.now();
    setState(() {
      _logs = logs;
      _week = weeklyStats(logs, now);
      _streak = computeStreak(logs);
      _level = levelFromXP(computeXP(logs, 0));
      _activePlan = Store.getActivePlan();
      _loading = false;
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final name = Store.userName;
    final unit = Store.weightUnit;
    final quote = _quotes[DateTime.now().day % _quotes.length];
    final vol = _week.volume;
    final volLabel = vol > 1000
        ? '${(vol / 1000).toStringAsFixed(1)}k'
        : vol.toStringAsFixed(0);

    final children = <Widget>[
      // Header
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateLabel,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                name.isEmpty ? _greeting : '$_greeting, ${name.split(' ').first}',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6),
              ),
            ],
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning, size: 22),
          ),
        ],
      ),

      const SizedBox(height: 18),

      // Quote
      GlassCard(
        child: Text('"$quote"',
            style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary)),
      ),

      const SizedBox(height: 14),

      // Level card
      GlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_level.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('Lv ${_level.level}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ProgressBar(pct: _level.progressPct),
                ],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // Stats grid
      Row(
        children: [
          _StatCard(
              icon: Icons.fitness_center_rounded,
              value: '${_week.count}',
              label: 'This Week',
              color: AppColors.accent),
          const SizedBox(width: 12),
          _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '${_streak}d',
              label: 'Streak',
              color: AppColors.warning),
          const SizedBox(width: 12),
          _StatCard(
              icon: Icons.trending_up_rounded,
              value: '$volLabel $unit',
              label: 'Volume',
              color: AppColors.success),
        ],
      ),

      const SizedBox(height: 14),

      // Week strip
      GlassCard(child: _WeekStrip(week: _week)),

      const SizedBox(height: 22),

      // Today's session
      _sectionHeader("Today's Session"),
      const SizedBox(height: 10),
      if (_activePlan?.nextSession != null)
        GlassCard(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_activePlan!.nextSession!.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                        '${_activePlan!.nextSession!.exercises.length} EX',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.list_alt_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('From: ${_activePlan!.name}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Start Workout',
                icon: Icons.play_arrow_rounded,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(
                        session: _activePlan!.nextSession!,
                        fromActivePlan: true))),
              ),
            ],
          ),
        )
      else
        GlassCard(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Freestyle Session',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text('READY',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 5),
                  Text('No active plan — build one or go freestyle',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Start Workout',
                icon: Icons.play_arrow_rounded,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const QuickWorkoutScreen())),
              ),
            ],
          ),
        ),

      const SizedBox(height: 22),

      // Recent activity
      _sectionHeader('Recent Activity'),
      const SizedBox(height: 10),
      if (_logs.isEmpty)
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Column(
            children: const [
              Icon(Icons.emoji_events_outlined, size: 34, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text('No workouts logged yet',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              SizedBox(height: 4),
              Text('Complete your first workout to see it here',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
            ],
          ),
        )
      else
        ..._logs.take(5).map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text('${l.duration} mins · ${l.exercises.length} exercises',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary),
                  ],
                ),
              ),
            )),

      const SizedBox(height: 24),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const BouncingScrollPhysics(),
        children: children
            .animate(interval: 55.ms)
            .fadeIn(duration: 340.ms)
            .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 3),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double pct;
  const _ProgressBar({required this.pct});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: (pct / 100).clamp(0, 1),
        minHeight: 6,
        backgroundColor: AppColors.bgElevated,
        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final WeekStats week;
  const _WeekStrip({required this.week});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayStr = localDateStr(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = week.weekStart.add(Duration(days: i));
        final key = localDateStr(d);
        final trained = week.trainedDates.contains(key);
        final isToday = key == todayStr;
        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: trained ? AppColors.brandGradient : null,
                color: trained ? null : AppColors.bgElevated,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: AppColors.accent, width: 1.5)
                    : null,
              ),
              child: trained
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(labels[i],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? AppColors.accent
                        : AppColors.textTertiary)),
          ],
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
