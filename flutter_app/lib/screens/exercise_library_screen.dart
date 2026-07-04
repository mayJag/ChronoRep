import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../data/exercises.dart';
import '../data/store.dart';
import '../data/models.dart';

const _muscles = ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'];
const _muscleLabels = {
  'chest': 'Chest', 'back': 'Back', 'shoulders': 'Shoulders',
  'arms': 'Arms', 'legs': 'Legs', 'core': 'Core',
};

/// Browse/search the built-in exercise library and add custom movements.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscleFilter;

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

  @override
  Widget build(BuildContext context) {
    final custom = Store.getCustomExercises();
    final all = <({String name, String muscleGroup, String category, bool isCustom})>[
      ...custom.map((c) => (
            name: c.name,
            muscleGroup: c.muscleGroup,
            category: c.category,
            isCustom: true
          )),
      ...kExercises.map((e) => (
            name: e.name,
            muscleGroup: e.muscleGroup,
            category: e.category,
            isCustom: false
          )),
    ];

    final filtered = all.where((e) {
      final matchesQuery =
          _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesMuscle = _muscleFilter == null || e.muscleGroup == _muscleFilter;
      return matchesQuery && matchesMuscle;
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
                _filterChip('All', null),
                ..._muscles.map((m) => _filterChip(_muscleLabels[m]!, m)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final e = filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        if (e.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGlow,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text('CUSTOM',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ),
                        Text(_muscleLabels[e.muscleGroup] ?? e.muscleGroup,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
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

  Widget _filterChip(String label, String? value) {
    final active = _muscleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _muscleFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: active ? Colors.transparent : AppColors.borderSubtle),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                .map((c) => _chip(c, c == _category, () => setState(() => _category = c)))
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
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: active ? Colors.transparent : AppColors.borderSubtle),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
        ),
      );
}
