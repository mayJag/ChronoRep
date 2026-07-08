import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/confirm_dialog.dart';
import '../data/active_plan.dart';
import '../data/store.dart';
import '../data/models.dart';
import '../data/fitness.dart';
import '../data/exercise_library.dart';
import '../data/substitutions.dart';

/// The core logging screen: per-exercise set rows (weight × reps), a rest
/// timer between sets, previous-performance tap-to-fill, and a
/// progressive-overload suggestion computed from lifetime history.
class ActiveWorkoutScreen extends StatefulWidget {
  final ActiveSession session;
  final bool fromActivePlan;
  const ActiveWorkoutScreen(
      {super.key, required this.session, this.fromActivePlan = false});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _SetState {
  final weightCtrl = TextEditingController();
  final repsCtrl = TextEditingController();
  bool done = false;
}

class _ExState {
  ActiveExercise ex; // mutable so an exercise can be swapped mid-session
  final List<_SetState> sets;
  String? suggestion;
  _ExState(this.ex, this.sets);
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final List<_ExState> _exercises;
  late final DateTime _start;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;
  bool _resting = false;

  // Exercise pool for the swap feature (curated + custom immediately, then the
  // full imported dataset streams in once its asset loads).
  List<LibraryExercise> _library = const [];

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _exercises = widget.session.exercises.map((ex) {
      final st = _ExState(ex, List.generate(ex.sets, (_) => _SetState()));
      _applySuggestion(st);
      return st;
    }).toList();
    _library = ExerciseLibrary.combined(Store.getCustomExercises(), const []);
    ExerciseLibrary.loadDataset().then((d) {
      if (mounted) {
        setState(() => _library =
            ExerciseLibrary.combined(Store.getCustomExercises(), d));
      }
    }).catchError((_) {});
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_start));
    });
  }

  /// Open a picker of ranked substitute exercises and swap the chosen one in,
  /// keeping the same set/rep/rest scheme.
  Future<void> _swap(_ExState st) async {
    final ref = LibraryExercise(
      name: st.ex.name,
      muscleGroup: st.ex.muscleGroup,
      category: st.ex.category,
      equipment: '',
    );
    final options = getSubstitutes(ref, _library, limit: 8);
    final picked = await showModalBottomSheet<LibraryExercise>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SwapSheet(original: st.ex.name, options: options),
    );
    if (picked == null || !mounted) return;
    setState(() {
      st.ex = ActiveExercise(picked.name, picked.muscleGroup, st.ex.sets,
          st.ex.reps, st.ex.restSec, picked.category);
      _applySuggestion(st);
    });
  }

  void _applySuggestion(_ExState st) {
    final best = Store.bestSetFor(st.ex.name);
    if (best == null) {
      st.suggestion = null;
      return;
    }
    final (lastWeight, lastReps, _) = best;
    final top = _topOfRange(st.ex.reps);
    final unit = Store.weightUnit;
    final increment = unit == 'lbs' ? 5.0 : 2.5;
    double sugWeight;
    int sugReps;
    if (lastReps >= top) {
      sugWeight = lastWeight + increment;
      sugReps = _bottomOfRange(st.ex.reps);
    } else {
      sugWeight = lastWeight;
      sugReps = lastReps + 1;
    }
    st.suggestion =
        '${sugWeight % 1 == 0 ? sugWeight.toStringAsFixed(0) : sugWeight.toStringAsFixed(1)} $unit × $sugReps';
    if (st.sets.isNotEmpty) {
      st.sets.first.weightCtrl.text =
          sugWeight % 1 == 0 ? sugWeight.toStringAsFixed(0) : sugWeight.toStringAsFixed(1);
      st.sets.first.repsCtrl.text = '$sugReps';
    }
  }

  int _topOfRange(String reps) {
    final nums = RegExp(r'\d+').allMatches(reps).map((m) => int.parse(m.group(0)!)).toList();
    return nums.isEmpty ? 10 : nums.last;
  }

  int _bottomOfRange(String reps) {
    final nums = RegExp(r'\d+').allMatches(reps).map((m) => int.parse(m.group(0)!)).toList();
    return nums.isEmpty ? 8 : nums.first;
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.weightCtrl.dispose();
        s.repsCtrl.dispose();
      }
    }
    super.dispose();
  }

  void _toggleDone(_SetState s, int restSec) {
    setState(() => s.done = !s.done);
    if (s.done) {
      HapticFeedback.mediumImpact();
      _startRest(restSec);
    }
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _resting = true;
      _restTotal = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restRemaining--);
      if (_restRemaining <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _resting = false);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _resting = false);
  }

  int get _completedSets =>
      _exercises.fold(0, (t, e) => t + e.sets.where((s) => s.done).length);

  double get _volume => _exercises.fold(0.0, (t, e) {
        return t +
            e.sets.where((s) => s.done).fold(0.0, (st, s) {
              final w = double.tryParse(s.weightCtrl.text) ?? 0;
              final r = int.tryParse(s.repsCtrl.text) ?? 0;
              return st + w * r;
            });
      });

  Future<void> _finish() async {
    final exercises = _exercises
        .where((e) => e.sets.any((s) => s.done))
        .map((e) => ExerciseLog(
            name: e.ex.name,
            sets: e.sets
                .where((s) => s.done)
                .map((s) => SetLog(
                    weight: double.tryParse(s.weightCtrl.text) ?? 0,
                    reps: int.tryParse(s.repsCtrl.text) ?? 0,
                    done: true))
                .toList()))
        .toList();

    if (exercises.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final log = WorkoutLog(
      id: genId(),
      name: widget.session.name,
      date: localDateStr(DateTime.now()),
      duration: (_elapsed.inSeconds / 60).round().clamp(1, 999),
      exercises: exercises,
    );
    await Store.saveLog(log);
    if (widget.fromActivePlan) await Store.advancePlanCursor();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => _FinishSummaryScreen(log: log),
    ));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Only interrupt with a confirm if there's logged progress to lose.
  Future<bool> _maybeQuit() async {
    if (_completedSets == 0) return true;
    return ConfirmDialog.danger(
      context,
      icon: Icons.logout_rounded,
      title: 'Quit workout?',
      message: "Your logged sets won't be saved. This can't be undone.",
      confirmLabel: 'Quit',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _maybeQuit()) navigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (await _maybeQuit()) navigator.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.session.name,
                style: AppFonts.display(16, weight: FontWeight.w700)),
            Text(_fmt(_elapsed),
                style: AppFonts.mono(12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: TextButton(
                onPressed: _finish,
                child: const Text('Finish',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: _exercises.length,
            itemBuilder: (context, i) => _ExerciseCard(
              state: _exercises[i],
              unit: Store.weightUnit,
              onToggle: (s) => _toggleDone(s, _exercises[i].ex.restSec),
              onSwap: () => _swap(_exercises[i]),
            ),
          ),
          if (_resting)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _RestBanner(
                remaining: _restRemaining,
                total: _restTotal,
                onSkip: _skipRest,
                onAdjust: (d) => setState(() {
                  _restRemaining = (_restRemaining + d).clamp(0, 3600);
                  _restTotal = (_restTotal + d).clamp(1, 3600);
                }),
              ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              ignoring: _resting,
              child: AnimatedOpacity(
                opacity: _resting ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_completedSets sets · ${_volume.toStringAsFixed(0)} ${Store.weightUnit}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _ExState state;
  final String unit;
  final ValueChanged<_SetState> onToggle;
  final VoidCallback onSwap;
  const _ExerciseCard(
      {required this.state,
      required this.unit,
      required this.onToggle,
      required this.onSwap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: state.ex.category == 'compound'
                        ? AppColors.accent
                        : AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(state.ex.name,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
                Text('${state.ex.reps} reps · ${state.ex.restSec}s rest',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: onSwap,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.swap_horiz_rounded,
                        size: 18, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
            if (state.suggestion != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('Suggested: ${state.suggestion}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: const [
                SizedBox(width: 28, child: Text('SET', style: _hdr)),
                Expanded(child: Center(child: Text('WEIGHT', style: _hdr))),
                Expanded(child: Center(child: Text('REPS', style: _hdr))),
                SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(state.sets.length, (i) {
              final s = state.sets[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}',
                          style: AppFonts.mono(13,
                              weight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(child: _numField(s.weightCtrl, s.done)),
                    const SizedBox(width: 8),
                    Expanded(child: _numField(s.repsCtrl, s.done)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: GestureDetector(
                        onTap: () => onToggle(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: s.done ? AppColors.success : AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: s.done
                                    ? Colors.transparent
                                    : AppColors.borderDefault),
                          ),
                          child: s.done
                              ? const Icon(Icons.check_rounded,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, bool done) => TextField(
        controller: c,
        enabled: !done,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppFonts.mono(14, weight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: AppColors.bgInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
        ),
      );

  static const _hdr = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AppColors.textTertiary);
}

/// Bottom sheet listing ranked substitute exercises; returns the chosen one.
class _SwapSheet extends StatelessWidget {
  final String original;
  final List<LibraryExercise> options;
  const _SwapSheet({required this.original, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Swap $original',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No close matches found for this exercise.',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final o = options[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, o),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${o.muscleGroup} · ${o.equipment}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.swap_horiz_rounded,
                                size: 18, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RestBanner extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onSkip;
  final ValueChanged<int> onAdjust;
  const _RestBanner(
      {required this.remaining,
      required this.total,
      required this.onSkip,
      required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return GlassCard(
      accent: true,
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 4,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
                Text('$remaining',
                    style: AppFonts.mono(13, weight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Resting',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          _pill('−15', () => onAdjust(-15)),
          const SizedBox(width: 6),
          _pill('+15', () => onAdjust(15)),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      );
}

class _FinishSummaryScreen extends StatelessWidget {
  final WorkoutLog log;
  const _FinishSummaryScreen({required this.log});

  @override
  Widget build(BuildContext context) {
    final sets = log.exercises.fold(0, (t, e) => t + e.sets.length);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
              ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 500.ms),
              const SizedBox(height: 20),
              const Text('Workout Complete',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text(log.name,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary))
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 28),
              Row(
                children: [
                  _stat('${log.duration}', 'MINUTES'),
                  _stat('$sets', 'SETS'),
                  _stat(log.volume > 999
                      ? '${(log.volume / 1000).toStringAsFixed(1)}k'
                      : log.volume.toStringAsFixed(0), 'VOLUME'),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: const Text('Done',
                            style: TextStyle(
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
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: AppFonts.mono(26, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
}
