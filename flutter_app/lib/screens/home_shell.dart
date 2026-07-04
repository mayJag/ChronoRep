import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'plan_screen.dart';
import 'placeholder_screen.dart';

/// Root scaffold with a custom animated bottom nav bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    _NavItem('Home', Icons.home_rounded),
    _NavItem('Plan', Icons.calendar_month_rounded),
    _NavItem('Progress', Icons.trending_up_rounded),
    _NavItem('History', Icons.bar_chart_rounded),
    _NavItem('More', Icons.grid_view_rounded),
  ];

  final _pages = const [
    DashboardScreen(),
    PlanScreen(),
    PlaceholderScreen(
      title: 'Progress',
      icon: Icons.trending_up_rounded,
      blurb: 'Volume trends, estimated 1RM strength curves, and lifetime totals.',
    ),
    PlaceholderScreen(
      title: 'History',
      icon: Icons.bar_chart_rounded,
      blurb: 'Every logged session with sets, volume, duration and personal records.',
    ),
    PlaceholderScreen(
      title: 'More',
      icon: Icons.grid_view_rounded,
      blurb: 'Body metrics, achievements, goals, calculators, library and settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: _AnimatedNavBar(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _AnimatedNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.items,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glow dot above the active icon.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        height: 4,
                        width: active ? 20 : 0,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      AnimatedScale(
                        scale: active ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          items[i].icon,
                          size: 22,
                          color: active
                              ? AppColors.accent
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                        child: Text(items[i].label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
