import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

abstract class _AppColors {
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFFEFF6FF);
  static const inactive = Color(0xFF9CA3AF);
}

// =============================================================================
// NAV ITEM CONFIGURATION
// =============================================================================

/// Configuration for a navigation tab item.
class NavItem {
  final int index;
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavItem({
    required this.index,
    required this.route,
    required this.icon,
    this.activeIcon,
    required this.label,
  });

  /// Get the appropriate icon based on selection state.
  IconData getIcon(bool isSelected) => isSelected ? (activeIcon ?? icon) : icon;
}

/// All navigation items in order.
const List<NavItem> navItems = [
  NavItem(
    index: 0,
    route: '/home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  NavItem(
    index: 1,
    route: '/workers',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: 'Workers',
  ),
  NavItem(
    index: 2,
    route: '/time-tracking',
    icon: Icons.access_time,
    activeIcon: Icons.access_time_filled,
    label: 'Time',
  ),
  NavItem(
    index: 3,
    route: '/subscriptions',
    icon: Icons.card_membership_outlined,
    activeIcon: Icons.card_membership,
    label: 'Plans',
  ),
  NavItem(
    index: 4,
    route: '/payroll',
    icon: Icons.account_balance_outlined,
    activeIcon: Icons.account_balance,
    label: 'Payroll',
  ),
  NavItem(
    index: 5,
    route: '/tax',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: 'Tax',
  ),
  NavItem(
    index: 6,
    route: '/finance',
    icon: Icons.attach_money_outlined,
    activeIcon: Icons.attach_money,
    label: 'Finance',
  ),
];

// =============================================================================
// MAIN LAYOUT
// =============================================================================

/// Main app layout with bottom navigation bar.
///
/// Wraps child pages and provides consistent navigation across the app.
class MainLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine if we should use compact mode based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: currentIndex,
        isCompact: isCompact,
        onItemTapped: (index) => _navigateToIndex(context, index),
      ),
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    if (index < 0 || index >= navItems.length) return;
    if (index == currentIndex) return; // Already on this tab

    // Haptic feedback for tab change
    HapticFeedback.selectionClick();

    context.go(navItems[index].route);
  }
}

// =============================================================================
// BOTTOM NAV BAR
// =============================================================================

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isCompact;
  final ValueChanged<int> onItemTapped;

  const _BottomNavBar({
    required this.currentIndex,
    required this.isCompact,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        border: const Border(
          top: BorderSide(color: _AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              return _NavTabItem(
                item: item,
                isSelected: currentIndex == item.index,
                isCompact: isCompact,
                onTap: () => onItemTapped(item.index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// NAV TAB ITEM
// =============================================================================

class _NavTabItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 4),
            _buildLabel(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCompact ? 28 : 32,
      height: isCompact ? 28 : 32,
      decoration: BoxDecoration(
        color: isSelected ? _AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.getIcon(isSelected),
        size: isCompact ? 18 : 20,
        color: isSelected ? _AppColors.primary : _AppColors.inactive,
      ),
    );
  }

  Widget _buildLabel() {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: isCompact ? 9 : 10,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? _AppColors.primary : _AppColors.inactive,
      ),
      child: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// =============================================================================
// ALTERNATIVE: SCROLLABLE NAV BAR (for many items)
// =============================================================================

/// A scrollable version of the bottom nav bar for when there are many items.
///
/// Use this if you need more than 5-6 items and horizontal space is limited.
class ScrollableBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  const ScrollableBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        border: const Border(
          top: BorderSide(color: _AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: navItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _NavTabItem(
                  item: item,
                  isSelected: currentIndex == item.index,
                  isCompact: false,
                  onTap: () => onItemTapped(item.index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ALTERNATIVE: DRAWER NAVIGATION (for tablet/desktop)
// =============================================================================

/// A navigation drawer for larger screens.
///
/// Use with `MainLayoutResponsive` for adaptive navigation.
class AppNavigationDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final bool isExpanded;

  const AppNavigationDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: onItemTapped,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'PayKey',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
        ...navItems.map((item) {
          return NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon ?? item.icon),
            label: Text(item.label),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// RESPONSIVE LAYOUT
// =============================================================================

/// Responsive main layout that switches between bottom nav and side drawer.
class MainLayoutResponsive extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  /// Breakpoint for switching to side navigation.
  static const double tabletBreakpoint = 768;

  const MainLayoutResponsive({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrLarger = screenWidth >= tabletBreakpoint;

    if (isTabletOrLarger) {
      return _buildWithDrawer(context);
    } else {
      return _buildWithBottomNav(context);
    }
  }

  Widget _buildWithDrawer(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppNavigationDrawer(
            currentIndex: currentIndex,
            onItemTapped: (index) => _navigateToIndex(context, index),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildWithBottomNav(BuildContext context) {
    return MainLayout(
      currentIndex: currentIndex,
      child: child,
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    if (index < 0 || index >= navItems.length) return;
    if (index == currentIndex) return;

    HapticFeedback.selectionClick();
    context.go(navItems[index].route);
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension to get NavItem by index.
extension NavItemsExtension on List<NavItem> {
  NavItem? byIndex(int index) {
    if (index < 0 || index >= length) return null;
    return firstWhere((item) => item.index == index);
  }

  NavItem? byRoute(String route) {
    try {
      return firstWhere((item) => item.route == route);
    } catch (_) {
      return null;
    }
  }
}