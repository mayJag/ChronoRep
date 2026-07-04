import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/plan_generator.dart';

/// Goal-driven, science-based plan builder. The user picks a goal, frequency,
/// experience and equipment; the generator guarantees the evidence-based
/// training frequency + weekly volume, shown transparently in a summary.
class ProgramBuilderScreen extends StatefulWidget {
  const ProgramBuilderScreen({super.key});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  Goal _goal = Goal.hypertrophy;
  int _days = 4;
  Experience _exp = Experience.intermediate;
  String _equip = 'full';
  bool _capTime = false;
  double _minutes = 60;

  GeneratedPlan? _plan;

  void _generate() {
    setState(() {
      _plan = generatePlan(
        goal: _goal,
        daysPerWeek: _days,
        experience: _exp,
        equipment: _equip,
        minutesPerSession: _capTime ? _minutes.round() : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Build a Plan',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          _label('YOUR GOAL'),
          const SizedBox(height: 8),
          ...Goal.values.map((g) => _GoalTile(
                goal: g,
                selected: _goal == g,
                onTap: () => setState(() => _goal = g),
              )),

          const SizedBox(height: 20),
          _label('DAYS PER WEEK'),
          const SizedBox(height: 8),
          _Segmented<int>(
            values: const [3, 4, 5, 6],
            labels: const ['3', '4', '5', '6'],
            selected: _days,
            onChanged: (v) => setState(() => _days = v),
          ),
          const SizedBox(height: 8),
          Text(chooseSplit(_days).rationale,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: AppColors.textSecondary)),

          const SizedBox(height: 20),
          _label('EXPERIENCE'),
          const SizedBox(height: 8),
          _Segmented<Experience>(
            values: Experience.values,
            labels: Experience.values.map((e) => e.label).toList(),
            selected: _exp,
            onChanged: (v) => setState(() => _exp = v),
          ),

          const SizedBox(height: 20),
          _label('EQUIPMENT'),
          const SizedBox(height: 8),
          _Segmented<String>(
            values: const ['full', 'dumbbell', 'bodyweight'],
            labels: const ['Full Gym', 'Dumbbells', 'Bodyweight'],
            selected: _equip,
            onChanged: (v) => setState(() => _equip = v),
          ),

          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Cap session length',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Switch(
                      value: _capTime,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _capTime = v),
                    ),
                  ],
                ),
                if (_capTime) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minutes,
                          min: 20,
                          max: 120,
                          divisions: 20,
                          activeColor: AppColors.accent,
                          inactiveColor: AppColors.bgElevated,
                          onChanged: (v) => setState(() => _minutes = v),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text('${_minutes.round()} min',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          _GenerateButton(onTap: _generate),

          if (_plan != null) ...[
            const SizedBox(height: 28),
            _PlanResult(plan: _plan!)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary));
}

class _GoalTile extends StatelessWidget {
  final Goal goal;
  final bool selected;
  final VoidCallback onTap;
  const _GoalTile(
      {required this.goal, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        accent: selected,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.brandGradient : null,
                color: selected ? null : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_iconFor(goal),
                  size: 20,
                  color: selected ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(goal.blurb,
                      style: const TextStyle(
                          fontSize: 12, height: 1.35, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.accent : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Goal g) => switch (g) {
        Goal.hypertrophy => Icons.fitness_center_rounded,
        Goal.strength => Icons.bolt_rounded,
        Goal.powerbuilding => Icons.shield_rounded,
        Goal.fatLoss => Icons.whatshot_rounded,
        Goal.general => Icons.favorite_rounded,
      };
}

class _Segmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  const _Segmented(
      {required this.values,
      required this.labels,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: List.generate(values.length, (i) {
          final active = values[i] == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: EdgeInsets.only(right: i == values.length - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  gradient: active ? AppColors.brandGradient : null,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GenerateButton({required this.onTap});

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
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text('Generate My Plan',
                    style: TextStyle(
                        fontSize: 16,
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

class _PlanResult extends StatelessWidget {
  final GeneratedPlan plan;
  const _PlanResult({required this.plan});

  @override
  Widget build(BuildContext context) {
    final freq = plan.weeklyFrequencyPerMuscle;
    final sets = plan.weeklySetsPerMuscle;
    final trainingDays = plan.week.where((d) => !d.rest).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(plan.split.label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),

        const SizedBox(height: 16),
        // Science summary
        GlassCard(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.science_rounded, size: 18, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Weekly Volume & Frequency',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Sets per muscle per week · times trained',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...muscleLabels.entries
                  .where((e) => (sets[e.key] ?? 0) > 0)
                  .map((e) => _MuscleRow(
                        label: e.value,
                        sets: sets[e.key] ?? 0,
                        freq: freq[e.key] ?? 0,
                      )),
            ],
          ),
        ),

        const SizedBox(height: 18),
        Text('THE WEEK',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        ...trainingDays.map((d) => _DayCard(day: d)),
      ],
    );
  }
}

class _MuscleRow extends StatelessWidget {
  final String label;
  final int sets;
  final int freq;
  const _MuscleRow({required this.label, required this.sets, required this.freq});

  @override
  Widget build(BuildContext context) {
    // 10–20 sets is the hypertrophy sweet spot; colour the bar by adequacy.
    final pct = (sets / 20).clamp(0.0, 1.0);
    final ok = freq >= 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 74,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: AppColors.bgElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text('$sets sets · $freq×',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ok ? AppColors.success : AppColors.warning)),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('~${day.estMinutes} min',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...day.exercises.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: e.category == 'compound'
                              ? AppColors.accent
                              : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(e.name,
                            style: const TextStyle(fontSize: 13.5)),
                      ),
                      Text('${e.sets} × ${e.reps}',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
