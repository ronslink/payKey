import 'package:flutter/material.dart';

/// Workers page constants
class WorkersConstants {
  WorkersConstants._();

  /// Routes
  static const String addWorkerRoute = '/workers/add';
  static const String importWorkersRoute = '/workers/import';
  static String workerDetailRoute(String id) => '/workers/$id';

  /// Filter options
  static const List<WorkerFilter> filters = [
    WorkerFilter.all,
    WorkerFilter.active,
    WorkerFilter.inactive,
    WorkerFilter.pending,
  ];

  /// Search debounce duration
  static const Duration searchDebounce = Duration(milliseconds: 300);
}

/// Worker filter enum with display labels
enum WorkerFilter {
  all('All'),
  active('Active'),
  inactive('Inactive'),
  pending('Pending');

  final String label;
  const WorkerFilter(this.label);
}

/// Workers theme constants
class WorkersTheme {
  WorkersTheme._();

  // Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color activeColor = Colors.green;
  static const Color inactiveColor = Colors.grey;
  static const MaterialColor warningColor = Colors.orange;
  static const Color totalColor = Colors.blue;

  // Dimensions
  static const double cardBorderRadius = 12.0;
  static const double chipBorderRadius = 20.0;
  static const double avatarSize = 48.0;
  static const double avatarBorderRadius = 12.0;
  static const double statusIndicatorSize = 14.0;
  static const double pagePadding = 16.0;

  // Card decoration
  static BoxDecoration cardDecoration({bool hasWarning = false}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      border: Border.all(
        color: hasWarning ? warningColor.shade200 : Colors.grey.shade200,
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
}

/// Stat item configuration
class WorkerStatConfig {
  final IconData icon;
  final String label;
  final Color color;

  const WorkerStatConfig({
    required this.icon,
    required this.label,
    required this.color,
  });

  static const total = WorkerStatConfig(
    icon: Icons.people_outlined,
    label: 'Total',
    color: WorkersTheme.totalColor,
  );

  static const active = WorkerStatConfig(
    icon: Icons.check_circle_outlined,
    label: 'Active',
    color: WorkersTheme.activeColor,
  );

  static const pending = WorkerStatConfig(
    icon: Icons.warning_amber_outlined,
    label: 'Pending',
    color: WorkersTheme.warningColor,
  );
}
