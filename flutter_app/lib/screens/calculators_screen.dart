import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/store.dart';

/// Three self-contained lifting calculators: estimated 1RM (Epley) with a
/// percentage table, a barbell plate loader, and a warm-up set builder.
class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Calculators',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  const labels = ['1RM', 'Plates', 'Warm-up'];
                  final active = i == _tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 4),
                        decoration: BoxDecoration(
                          gradient: active ? AppColors.brandGradient : null,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _OneRepMax(),
                _PlateLoader(),
                _WarmupBuilder(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDeco(String hint, {String? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );

// ---------------- 1RM ----------------
class _OneRepMax extends StatefulWidget {
  const _OneRepMax();
  @override
  State<_OneRepMax> createState() => _OneRepMaxState();
}

class _OneRepMaxState extends State<_OneRepMax> {
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  double? _oneRm;

  void _calc() {
    final w = double.tryParse(_weight.text);
    final r = int.tryParse(_reps.text);
    if (w == null || r == null || r < 1) {
      setState(() => _oneRm = null);
      return;
    }
    // Epley formula. At 1 rep it returns the input weight.
    setState(() => _oneRm = r == 1 ? w : w * (1 + r / 30));
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = Store.weightUnit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.accent,
                      onChanged: (_) => _calc(),
                      decoration: _fieldDeco('Weight', suffix: unit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.accent,
                      onChanged: (_) => _calc(),
                      decoration: _fieldDeco('Reps'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_oneRm != null) ...[
          GlassCard(
            accent: true,
            child: Column(
              children: [
                const Text('ESTIMATED 1RM',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                  child: Text('${_oneRm!.toStringAsFixed(1)} $unit',
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('TRAINING PERCENTAGES',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [95, 90, 85, 80, 75, 70, 65, 60].map((p) {
                final val = _oneRm! * p / 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$p%',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                      Text('${val.toStringAsFixed(1)} $unit',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(_repHint(p),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Enter a weight and reps to estimate your 1RM.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary)),
          ),
      ],
    );
  }

  String _repHint(int p) => switch (p) {
        95 => '~2 reps',
        90 => '~4 reps',
        85 => '~6 reps',
        80 => '~8 reps',
        75 => '~10 reps',
        70 => '~12 reps',
        65 => '~15 reps',
        _ => '~18 reps',
      };
}

// ---------------- Plate loader ----------------
class _PlateLoader extends StatefulWidget {
  const _PlateLoader();
  @override
  State<_PlateLoader> createState() => _PlateLoaderState();
}

class _PlateLoaderState extends State<_PlateLoader> {
  final _target = TextEditingController();
  double _bar = 20;
  List<double>? _perSide;
  double _leftover = 0;

  static const _plates = <double>[25, 20, 15, 10, 5, 2.5, 1.25];

  void _calc() {
    final t = double.tryParse(_target.text);
    if (t == null || t < _bar) {
      setState(() => _perSide = null);
      return;
    }
    var perSide = (t - _bar) / 2;
    final out = <double>[];
    for (final p in _plates) {
      while (perSide >= p - 1e-9) {
        out.add(p);
        perSide -= p;
      }
    }
    setState(() {
      _perSide = out;
      _leftover = perSide;
    });
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = Store.weightUnit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                cursorColor: AppColors.accent,
                onChanged: (_) => _calc(),
                decoration: _fieldDeco('Target total weight', suffix: unit),
              ),
              const SizedBox(height: 14),
              const Text('Bar weight',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: <double>[20, 15, 10].map((b) {
                  final active = _bar == b;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _bar = b;
                        _calc();
                      }),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: active ? AppColors.brandGradient : null,
                          color: active ? null : AppColors.bgInput,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : AppColors.borderSubtle),
                        ),
                        child: Text('${b.toStringAsFixed(0)} $unit',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    active ? Colors.white : AppColors.textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_perSide != null)
          GlassCard(
            accent: true,
            child: Column(
              children: [
                const Text('LOAD PER SIDE',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                if (_perSide!.isEmpty)
                  const Text('Just the bar.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _perSide!
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border:
                                    Border.all(color: AppColors.borderAccent),
                              ),
                              child: Text(
                                  p.toStringAsFixed(p == p.roundToDouble() ? 0 : 2),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ))
                        .toList(),
                  ),
                if (_leftover > 0.01) ...[
                  const SizedBox(height: 10),
                  Text(
                      'Cannot make exactly — ${(_leftover * 2).toStringAsFixed(2)} $unit short.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.warning)),
                ],
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Enter a target weight to see plates per side.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary)),
          ),
      ],
    );
  }
}

// ---------------- Warm-up builder ----------------
class _WarmupBuilder extends StatefulWidget {
  const _WarmupBuilder();
  @override
  State<_WarmupBuilder> createState() => _WarmupBuilderState();
}

class _WarmupBuilderState extends State<_WarmupBuilder> {
  final _working = TextEditingController();
  List<(String, int, double)>? _sets; // label, reps, weight

  void _calc() {
    final w = double.tryParse(_working.text);
    if (w == null || w <= 0) {
      setState(() => _sets = null);
      return;
    }
    // Standard ramp: empty bar-ish → 40/60/80% then working.
    setState(() => _sets = [
          ('Warm-up 1', 8, w * 0.4),
          ('Warm-up 2', 5, w * 0.6),
          ('Warm-up 3', 3, w * 0.8),
          ('Working', 0, w),
        ]);
  }

  @override
  void dispose() {
    _working.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = Store.weightUnit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        GlassCard(
          child: TextField(
            controller: _working,
            keyboardType: TextInputType.number,
            cursorColor: AppColors.accent,
            onChanged: (_) => _calc(),
            decoration: _fieldDeco('Working set weight', suffix: unit),
          ),
        ),
        const SizedBox(height: 16),
        if (_sets != null)
          ..._sets!.map((s) {
            final isWorking = s.$2 == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                accent: isWorking,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.$1,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isWorking
                                  ? AppColors.accent
                                  : AppColors.textPrimary)),
                    ),
                    Text(
                        isWorking
                            ? '${s.$3.toStringAsFixed(1)} $unit'
                            : '${s.$2} × ${s.$3.toStringAsFixed(1)} $unit',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          })
        else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Enter your working weight for a warm-up ramp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary)),
          ),
      ],
    );
  }
}
