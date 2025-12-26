import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// New main layout with redesigned bottom navigation (5 items, no FAB)
class MainLayoutNew extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayoutNew({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  State<MainLayoutNew> createState() => _MainLayoutNewState();
}

class _MainLayoutNewState extends State<MainLayoutNew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home', '/home'),
                _buildNavItem(context, 1, Icons.people_outline, Icons.people, 'People', '/workers'),
                _buildNavItem(context, 2, Icons.play_circle_outline, Icons.play_circle, 'Payroll', '/payroll/run'),
                _buildNavItem(context, 3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Finance', '/finance'),
                _buildNavItem(context, 4, Icons.settings_outlined, Icons.settings, 'Settings', '/settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label, String route) {
    final isActive = widget.currentIndex == index;
    final color = isActive ? Theme.of(context).primaryColor : Colors.grey.shade600;

    return InkWell(
      onTap: () {
        if (!isActive) {
          if (route == '/payroll/run') {
            context.push(route); // Push for payroll run (modal-like behavior)
          } else {
            context.go(route); // Go for tab navigation
          }
        }
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
