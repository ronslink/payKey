import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// New main layout with redesigned bottom navigation (5 items, no FAB)
class MainLayoutNew extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayoutNew({super.key, required this.child, this.currentIndex = 0});

  @override
  State<MainLayoutNew> createState() => _MainLayoutNewState();
}

class _MainLayoutNewState extends State<MainLayoutNew> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 65),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    0,
                    Icons.home_outlined,
                    Icons.home,
                    'Home',
                    '/home',
                  ),
                  _buildNavItem(
                    context,
                    1,
                    Icons.people_outline,
                    Icons.people,
                    'People',
                    '/workers',
                  ),
                  _buildNavItem(
                    context,
                    2,
                    Icons.list_alt,
                    Icons.list_alt,
                    'Payroll',
                    '/payroll',
                  ),
                  _buildNavItem(
                    context,
                    3,
                    Icons.account_balance_wallet_outlined,
                    Icons.account_balance_wallet,
                    'Finance',
                    '/finance',
                  ),
                  _buildNavItem(
                    context,
                    4,
                    Icons.settings_outlined,
                    Icons.settings,
                    'Settings',
                    '/settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    String route,
  ) {
    final isActive = widget.currentIndex == index;
    final colors = Theme.of(context).colorScheme;
    final color = isActive ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        selected: isActive,
        button: true,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              context.go(route); // Go for tab navigation
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
