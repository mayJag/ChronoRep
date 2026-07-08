import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/confirm_dialog.dart';
import '../data/store.dart';

/// Profile + unit settings. Persists to the same store the Dashboard reads,
/// so the greeting and volume unit update immediately on next open.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: Store.userName);
    _unit = Store.weightUnit;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await Store.setUserName(_name.text.trim());
    await Store.setWeightUnit(_unit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Saved'),
      backgroundColor: AppColors.bgElevated,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _clearHistory() async {
    final ok = await ConfirmDialog.danger(
      context,
      icon: Icons.history_toggle_off_rounded,
      title: 'Clear workout history?',
      message:
          "Every logged session will be permanently deleted. Your plan, goals, and settings stay. This can't be undone.",
      confirmLabel: 'Clear History',
    );
    if (!ok) return;
    await Store.clearHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Workout history cleared'),
      backgroundColor: AppColors.bgElevated,
    ));
  }

  Future<void> _resetAll() async {
    final ok = await ConfirmDialog.danger(
      context,
      icon: Icons.restart_alt_rounded,
      title: 'Reset all app data?',
      message:
          'This erases your profile, plan, goals, body metrics, custom exercises, and every logged session.',
      confirmLabel: 'Reset Everything',
    );
    if (!ok || !mounted) return;
    // Destructive enough to warrant a second, explicit confirmation.
    final sure = await ConfirmDialog.danger(
      context,
      icon: Icons.warning_amber_rounded,
      title: 'Are you absolutely sure?',
      message:
          'This action is irreversible. All ChronoRep data on this device will be gone.',
      confirmLabel: 'Yes, Reset All',
    );
    if (!sure) return;
    await Store.resetAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('All data reset'),
      backgroundColor: AppColors.bgElevated,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _label('PROFILE'),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your name',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: 'e.g. Chinmay',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Used for your dashboard greeting.',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _label('UNITS'),
          const SizedBox(height: 8),
          GlassCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('Weight unit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                _UnitToggle(
                  unit: _unit,
                  onChanged: (u) => setState(() => _unit = u),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
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
                  child: const Text('Save',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              _label('MAINTENANCE'),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                    height: 1, color: AppColors.danger.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _DangerRow(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Clear Workout History',
                  subtitle: 'Delete every logged session',
                  onTap: _clearHistory,
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                _DangerRow(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset All Application Data',
                  subtitle: 'Erase everything and start fresh',
                  onTap: _resetAll,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text('ChronoRep v1.9.0',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppColors.textTertiary)),
          ),
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

class _UnitToggle extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onChanged;
  const _UnitToggle({required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: ['kg', 'lbs'].map((u) {
          final active = u == unit;
          return GestureDetector(
            onTap: () => onChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? AppColors.brandGradient : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(u,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSecondary)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DangerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.dangerGlow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 19, color: AppColors.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
