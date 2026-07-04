import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/store.dart';
import '../data/models.dart';

/// Concrete, trackable goals (hit X kg on a lift, reach a target bodyweight),
/// with progress computed live from logged history — distinct from the
/// Program Builder, which plans *how* you train rather than a target number.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  double? _currentFor(UserGoal g) {
    if (g.type == GoalType.bodyweight) {
      final metrics = Store.getBodyMetrics();
      return metrics.isEmpty ? null : metrics.last.weight;
    }
    final best = Store.bestSetFor(g.label);
    return best?.$1;
  }

  Future<void> _addGoal() async {
    final result = await showModalBottomSheet<UserGoal>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddGoalSheet(),
    );
    if (result != null) {
      await Store.saveGoal(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = Store.getGoals();
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Goals',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addGoal,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Add Goal',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (goals.isEmpty)
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  children: const [
                    Icon(Icons.flag_rounded, size: 32, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text('No goals yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Set a lift target or a bodyweight goal to track progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                  ],
                ),
              )
            else
              ...goals.map((g) => _GoalCard(
                    goal: g,
                    current: _currentFor(g),
                    onDelete: () async {
                      await Store.deleteGoal(g.id);
                      setState(() {});
                    },
                  )),
          ].animate(interval: 60.ms).fadeIn(duration: 280.ms),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final UserGoal goal;
  final double? current;
  final VoidCallback onDelete;
  const _GoalCard({required this.goal, required this.current, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final unit = Store.weightUnit;
    final cur = current ?? goal.startValue;
    final span = (goal.target - goal.startValue);
    final pct = span == 0 ? 0.0 : ((cur - goal.startValue) / span).clamp(0.0, 1.0);
    final reached = goal.target >= goal.startValue ? cur >= goal.target : cur <= goal.target;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        accent: reached,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    goal.type == GoalType.bodyweight
                        ? Icons.monitor_weight_rounded
                        : Icons.fitness_center_rounded,
                    size: 18,
                    color: reached ? AppColors.success : AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(goal.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textTertiary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: AppColors.bgElevated,
                valueColor: AlwaysStoppedAnimation(
                    reached ? AppColors.success : AppColors.accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${cur.toStringAsFixed(1)} $unit',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(reached ? 'Goal reached! 🎉' : 'Target: ${goal.target.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reached ? AppColors.success : AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();
  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  GoalType _type = GoalType.liftWeight;
  final _label = TextEditingController(text: 'Bench Press');
  final _target = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _target.dispose();
    super.dispose();
  }

  void _save() {
    final t = double.tryParse(_target.text);
    if (t == null) return;
    double start = 0;
    if (_type == GoalType.bodyweight) {
      final metrics = Store.getBodyMetrics();
      start = metrics.isEmpty ? t : metrics.last.weight;
    } else {
      start = Store.bestSetFor(_label.text)?.$1 ?? 0;
    }
    Navigator.pop(
      context,
      UserGoal(
        id: genId(),
        type: _type,
        label: _type == GoalType.bodyweight ? 'Bodyweight' : _label.text,
        target: t,
        startValue: start,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _typeChip('Lift Target', GoalType.liftWeight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeChip('Bodyweight', GoalType.bodyweight),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_type == GoalType.liftWeight)
            TextField(
              controller: _label,
              style: const TextStyle(fontSize: 15),
              decoration: _deco('Exercise name'),
            ),
          if (_type == GoalType.liftWeight) const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15),
            decoration: _deco(
                _type == GoalType.bodyweight ? 'Target weight' : 'Target lift weight'),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _save,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: const Text('Save Goal',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, GoalType type) {
    final active = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: active ? Colors.transparent : AppColors.borderSubtle),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      );
}
