import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/store.dart';
import '../data/models.dart';
import '../data/exercise_library.dart';

const _muscles = ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'];
const _muscleLabels = {
  'chest': 'Chest', 'back': 'Back', 'shoulders': 'Shoulders',
  'arms': 'Arms', 'legs': 'Legs', 'core': 'Core',
  'cardio': 'Cardio', 'neck': 'Neck', 'full_body': 'Full Body',
};
const _equipment = [
  'barbell', 'dumbbell', 'machine', 'cable', 'bodyweight', 'band', 'kettlebell',
];

/// Browse/search the full exercise library (curated staples + 1,300+ imported
/// movements + custom), filter by muscle and equipment, and tap any exercise
/// for its target muscles and step-by-step instructions.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscleFilter;
  String? _equipmentFilter;
  List<LibraryExercise> _dataset = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ExerciseLibrary.loadDataset().then((d) {
      if (mounted) setState(() {
        _dataset = d;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _addCustom() async {
    final result = await showModalBottomSheet<CustomExercise>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddExerciseSheet(),
    );
    if (result != null) {
      await Store.saveCustomExercise(result);
      setState(() {});
    }
  }

  void _showDetail(LibraryExercise e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExerciseDetailSheet(exercise: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom = Store.getCustomExercises();
    final all = ExerciseLibrary.combined(custom, _dataset);

    final filtered = all.where((e) {
      final matchesQuery =
          _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesMuscle =
          _muscleFilter == null || e.muscleGroup == _muscleFilter;
      final matchesEquip =
          _equipmentFilter == null || e.equipment == _equipmentFilter;
      return matchesQuery && matchesMuscle && matchesEquip;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Exercise Library',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        actions: [
          IconButton(
            onPressed: _addCustom,
            icon: const Icon(Icons.add_rounded, color: AppColors.accent),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search exercises',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.bgInput,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', null, _muscleFilter,
                    (v) => setState(() => _muscleFilter = v)),
                ..._muscles.map((m) => _filterChip(_muscleLabels[m]!, m,
                    _muscleFilter, (v) => setState(() => _muscleFilter = v))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('Any gear', null, _equipmentFilter,
                    (v) => setState(() => _equipmentFilter = v), small: true),
                ..._equipment.map((eq) => _filterChip(
                    eq[0].toUpperCase() + eq.substring(1), eq, _equipmentFilter,
                    (v) => setState(() => _equipmentFilter = v), small: true)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loading
                    ? 'Loading library…'
                    : '${filtered.length} exercise${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textTertiary),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final e = filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _showDetail(e),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${_muscleLabels[e.muscleGroup] ?? e.muscleGroup} · ${e.equipment}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (e.custom)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accentGlow,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Text('CUSTOM',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(duration: 240.ms),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, String? current,
      ValueChanged<String?> onSelect,
      {bool small = false}) {
    final active = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 14, vertical: small ? 6 : 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
                color: active ? Colors.transparent : AppColors.borderSubtle),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: small ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

/// Bottom sheet showing an exercise's target muscles and step-by-step
/// instructions (for dataset entries) or a simple summary (curated/custom).
class _ExerciseDetailSheet extends StatelessWidget {
  final LibraryExercise exercise;
  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
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
            Text(e.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '${_muscleLabels[e.muscleGroup] ?? e.muscleGroup} · ${e.category} · ${e.equipment}'
              '${e.target != null ? ' · targets ${e.target}' : ''}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
            if (e.secondaryMuscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Also works: ${e.secondaryMuscles.join(', ')}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 18),
            if (e.instructions.isNotEmpty) ...[
              const Text('Instructions',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...List.generate(e.instructions.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentGlow,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ),
                      Expanded(
                        child: Text(e.instructions[i],
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                );
              }),
            ] else
              const Text('No step-by-step instructions available yet.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet();
  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _name = TextEditingController();
  String _muscle = 'chest';
  String _category = 'compound';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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
          const Text('Add Custom Exercise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              hintText: 'Exercise name',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscles
                .map((m) => _chip(_muscleLabels[m]!, m == _muscle,
                    () => setState(() => _muscle = m)))
                .toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: ['compound', 'isolation', 'core']
                .map((c) =>
                    _chip(c, c == _category, () => setState(() => _category = c)))
                .toList(),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_name.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  CustomExercise(
                    name: _name.text.trim(),
                    muscleGroup: _muscle,
                    category: _category,
                    equipment: 'other',
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: const Text('Add Exercise',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
                color: active ? Colors.transparent : AppColors.borderSubtle),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
        ),
      );
}
