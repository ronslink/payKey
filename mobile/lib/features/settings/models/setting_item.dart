import 'package:flutter/material.dart';

/// Model representing a single setting item in a settings card
@immutable
class SettingItem {
  /// Icon displayed on the left
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle/description text
  final String? subtitle;

  /// Optional custom trailing widget (e.g., Switch)
  final Widget? trailing;

  /// Custom icon color (defaults to grey)
  final Color? iconColor;

  /// Custom title color (for danger actions like logout)
  final Color? titleColor;

  /// Tap handler - if null, no chevron is shown
  final VoidCallback? onTap;

  const SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  /// Whether this item is tappable
  bool get isTappable => onTap != null;

  /// Whether this item has a custom trailing widget
  bool get hasCustomTrailing => trailing != null;

  /// Create a copy with modified properties
  SettingItem copyWith({
    IconData? icon,
    String? title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return SettingItem(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Model for quick access grid items
@immutable
class QuickAccessItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const QuickAccessItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

/// Predefined quick access items
class QuickAccessItems {
  QuickAccessItems._();

  static const List<QuickAccessItem> defaults = [
    QuickAccessItem(
      icon: Icons.people_alt_outlined,
      label: 'Workers',
      route: '/workers',
      color: Colors.blue,
    ),
    QuickAccessItem(
      icon: Icons.account_balance_outlined,
      label: 'Tax',
      route: '/taxes',
      color: Colors.orange,
    ),
    QuickAccessItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Finance',
      route: '/finance',
      color: Colors.green,
    ),
    QuickAccessItem(
      icon: Icons.credit_card_outlined,
      label: 'Subscription',
      route: '/settings/subscription',
      color: Colors.purple,
    ),
  ];
}
