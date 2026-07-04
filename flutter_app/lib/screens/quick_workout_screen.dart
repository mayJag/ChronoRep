import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/plan_generator.dart';

/// "I've got X minutes" → a session sized to fit the available time.
class QuickWorkoutScreen extends StatefulWidget {
  const QuickWorkoutScreen({super.key});

  @override
  State<QuickWorkoutScreen> createState() => _QuickWorkoutScreenState();
}

class _QuickWorkoutScreenState extends State<QuickWorkoutScreen> {
  int _minutes = 30;
  final String _equip = 'full';
  final _focus = <String>{'chest', 'back', 'shoulders', 'arms', 'legs'};
  PlanDay? _session;

  static const _allFocus = {
    'chest': 'Chest',
    'back': 'Back',
    'shoulders': 'Shoulders',
    'arms': 'Arms',
    'legs': 'Legs',
    'core': 'Core',
  };

  void _generate() {
    setState(() {
      _session = generateQuickSession(
        minutes: _minutes,
        equipment: _equip,
        focus: _focus.toList(),
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
        title: const Text('Quick Workout',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text('How much time do you have?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Big time read-out
          Center(
            child: ShaderMask(
              shaderCallback: (r) => AppColors.brandGradient.createShader(r),
              child: Text('$_minutes',
                  style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1)),
            ),
          ),
          const Center(
            child: Text('MINUTES',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minutes.toDouble(),
            min: 15,
            max: 90,
            divisions: 15,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.bgElevated,
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [15, 30, 45, 60].map((m) {
              final active = _minutes == m;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _minutes = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentGlow : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: active ? AppColors.borderAccent : AppColors.borderSubtle),
                    ),
                    child: Text('${m}m',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.accent : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Text('Focus',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allFocus.entries.map((e) {
              final on = _focus.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (on) {
                    if (_focus.length > 1) _focus.remove(e.key);
                  } else {
                    _focus.add(e.key);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: on ? AppColors.brandGradient : null,
                    color: on ? null : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: on ? Colors.transparent : AppColors.borderSubtle),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: on ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _generate,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  child: const Text('Build Session',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ),

          if (_session != null) ...[
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_session!.exercises.length} exercises',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('~${_session!.estMinutes} min',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            ..._session!.exercises.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: e.category == 'compound'
                                ? AppColors.accent
                                : AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(e.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Text('${e.sets} × ${e.reps}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ))
                .toList()
                .animate(interval: 40.ms)
                .fadeIn(duration: 260.ms)
                .slideX(begin: 0.06, end: 0),
          ],
        ],
      ),
    );
  }
}
