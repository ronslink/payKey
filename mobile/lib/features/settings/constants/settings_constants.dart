import 'package:flutter/material.dart';

/// App metadata and version info
class AppInfo {
  AppInfo._();

  static const String appName = 'PayKey';
  static const String version = '2.1.0';
  static const String copyright = '© 2024 PayKey Kenya';
  static const String tagline = 'Your all-in-one payroll solution for domestic workers.';

  static String get fullVersion => '$appName v$version';
  static String get aboutText => '$fullVersion\n\n$tagline\n\n$copyright';
}

/// Route constants for settings navigation
class SettingsRoutes {
  SettingsRoutes._();

  static const String properties = '/properties';
  static const String timeTracking = '/time-tracking';
  static const String leave = '/leave';
  static const String reports = '/reports';
  static const String subscription = '/settings/subscription';
  static const String security = '/settings/security';
  static const String profileEdit = '/profile/edit';
  static const String login = '/login';
}

/// Theme constants for settings UI
class SettingsTheme {
  SettingsTheme._();

  // Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color dangerColor = Colors.red;

  // Dimensions
  static const double cardBorderRadius = 12.0;
  static const double profileCardBorderRadius = 16.0;
  static const double bottomSheetBorderRadius = 20.0;
  static const double iconContainerSize = 56.0;
  static const double iconContainerRadius = 14.0;
  static const double settingIconSize = 20.0;
  static const double quickAccessIconSize = 22.0;

  // Padding
  static const double pagePadding = 16.0;
  static const double cardPadding = 20.0;
  static const double tilePaddingHorizontal = 16.0;
  static const double tilePaddingVertical = 14.0;
  static const double sectionLabelTopPadding = 24.0;
  static const double sectionLabelBottomPadding = 12.0;

  // Grid
  static const int quickAccessColumns = 3;
  static const double quickAccessSpacing = 12.0;

  // Bottom sheet decoration
  static ShapeDecoration get bottomSheetDecoration => const ShapeDecoration(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(bottomSheetBorderRadius),
          ),
        ),
      );

  // Card decoration
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Profile card gradient
  static LinearGradient profileGradient(Color primaryColor) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.85),
        ],
      );
}

/// Frequency display names
class FrequencyLabels {
  FrequencyLabels._();

  static const Map<String, String> labels = {
    'WEEKLY': 'Weekly',
    'BIWEEKLY': 'Bi-Weekly',
    'MONTHLY': 'Monthly',
  };

  static String format(String frequency) => labels[frequency] ?? frequency;

  static List<String> get allValues => labels.keys.toList();
}

/// Employment type display names
class EmploymentTypeLabels {
  EmploymentTypeLabels._();

  static const Map<String, String> labels = {
    'FIXED': 'Fixed Salary',
    'HOURLY': 'Hourly',
  };

  static String format(String type) => labels[type] ?? type;

  static List<String> get allValues => labels.keys.toList();
}

/// Payment method display names
class PaymentMethodLabels {
  PaymentMethodLabels._();

  static const Map<String, String> labels = {
    'BANK': 'Bank Transfer',
    'MPESA': 'M-Pesa',
  };

  static String format(String method) => labels[method] ?? method;

  static List<String> get allValues => labels.keys.toList();
}
