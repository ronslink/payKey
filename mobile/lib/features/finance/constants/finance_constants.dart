import 'package:flutter/material.dart';

/// Finance page constants
class FinanceConstants {
  FinanceConstants._();

  /// Default currency code
  static const String currencyCode = 'KES';

  /// Maximum number of recent transactions to show
  static const int maxRecentTransactions = 5;

  /// Routes
  static const String topUpRoute = '/payments/topup';
  static const String settingsRoute = '/settings';
  static const String reportsRoute = '/reports';
  static const String runPayrollRoute = '/payroll/run';
  static const String accountingRoute = '/accounting';
}

/// Finance theme constants
class FinanceTheme {
  FinanceTheme._();

  // Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color successColor = Colors.green;
  static const Color trendUpColor = Colors.greenAccent;
  static const Color trendDownColor = Colors.redAccent;

  // Dimensions
  static const double cardBorderRadius = 12.0;
  static const double statusCardBorderRadius = 16.0;
  static const double pagePadding = 16.0;
  static const double cardPadding = 20.0;
  static const double actionButtonPadding = 14.0;
  static const double progressBarHeight = 6.0;

  // Section spacing
  static const double sectionLabelTopPadding = 24.0;
  static const double sectionLabelBottomPadding = 12.0;

  // Card decoration
  static BoxDecoration cardDecoration({
    bool isActive = false,
    Color? activeColor,
  }) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      border: Border.all(
        color: isActive ? (activeColor ?? Colors.blue) : Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Status card gradient
  static LinearGradient statusGradient(Color primaryColor) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.85),
        ],
      );

  // Status card shadow
  static List<BoxShadow> statusCardShadow(Color primaryColor) => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Quick action item model
class QuickActionItem {
  final IconData icon;
  final String label;
  final String route;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Default quick actions
class QuickActions {
  QuickActions._();

  static const List<QuickActionItem> defaults = [
    QuickActionItem(
      icon: Icons.add_circle_outline,
      label: 'Add Funds',
      route: FinanceConstants.topUpRoute,
    ),
    QuickActionItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: FinanceConstants.settingsRoute,
    ),
    QuickActionItem(
      icon: Icons.download_outlined,
      label: 'Report',
      route: FinanceConstants.reportsRoute,
    ),
    QuickActionItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Accounting',
      route: FinanceConstants.accountingRoute,
    ),
  ];
}
