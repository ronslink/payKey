import 'package:flutter/material.dart';

/// Keys for tracking tour and tip progress
/// 
/// Add new keys here when creating new tours or tips.
/// Use descriptive prefixes: `tour_` for multi-step tours, `tip_` for single tips.
class TourKeys {
  TourKeys._();

  // Tours (multi-step guided experiences)
  static const String dashboardTour = 'tour_dashboard';
  static const String payrollTour = 'tour_payroll';
  static const String workersTour = 'tour_workers';
  static const String reportsTour = 'tour_reports';

  // Tips (single contextual hints)
  static const String tipFirstWorker = 'tip_first_worker';
  static const String tipFirstPayroll = 'tip_first_payroll';
  static const String tipLeaveManagement = 'tip_leave_management';
  static const String tipTimeTracking = 'tip_time_tracking';
  static const String tipReports = 'tip_reports';

  /// All tour keys for bulk operations
  static const List<String> allTours = [
    dashboardTour,
    payrollTour,
    workersTour,
    reportsTour,
  ];

  /// All tip keys for bulk operations
  static const List<String> allTips = [
    tipFirstWorker,
    tipFirstPayroll,
    tipLeaveManagement,
    tipTimeTracking,
    tipReports,
  ];
}

/// Position of the tour tooltip relative to the target element
enum TourStepPosition {
  above,
  below,
  left,
  right,
}

/// A single step in a guided tour
@immutable
class TourStep {
  /// GlobalKey of the widget to highlight
  final GlobalKey targetKey;

  /// Title shown in the tooltip
  final String title;

  /// Description text explaining the feature
  final String description;

  /// Position of tooltip relative to target
  final TourStepPosition position;

  /// Whether this is the final step
  final bool isLast;

  /// Optional icon to display in the tooltip header
  final IconData? icon;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TourStepPosition.below,
    this.isLast = false,
    this.icon,
  });

  /// Create a copy with modified properties
  TourStep copyWith({
    GlobalKey? targetKey,
    String? title,
    String? description,
    TourStepPosition? position,
    bool? isLast,
    IconData? icon,
  }) {
    return TourStep(
      targetKey: targetKey ?? this.targetKey,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      isLast: isLast ?? this.isLast,
      icon: icon ?? this.icon,
    );
  }
}

/// Model for tracking tour and tip completion status
@immutable
class TourProgress {
  final Set<String> completedTours;
  final Set<String> dismissedTips;
  final DateTime? lastTourShown;
  final bool isLoaded;
  final bool onboardingCompleted;
  final String? error;

  const TourProgress({
    this.completedTours = const {},
    this.dismissedTips = const {},
    this.lastTourShown,
    this.isLoaded = false,
    this.onboardingCompleted = false,
    this.error,
  });

  /// Create initial loading state
  const TourProgress.loading()
      : completedTours = const {},
        dismissedTips = const {},
        lastTourShown = null,
        isLoaded = false,
        onboardingCompleted = false,
        error = null;

  /// Create error state
  const TourProgress.withError(String errorMessage)
      : completedTours = const {},
        dismissedTips = const {},
        lastTourShown = null,
        isLoaded = true,
        onboardingCompleted = false,
        error = errorMessage;

  TourProgress copyWith({
    Set<String>? completedTours,
    Set<String>? dismissedTips,
    DateTime? lastTourShown,
    bool? isLoaded,
    bool? onboardingCompleted,
    String? error,
  }) {
    return TourProgress(
      completedTours: completedTours ?? this.completedTours,
      dismissedTips: dismissedTips ?? this.dismissedTips,
      lastTourShown: lastTourShown ?? this.lastTourShown,
      isLoaded: isLoaded ?? this.isLoaded,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      error: error,
    );
  }

  /// Check if a tour or tip has been seen
  bool hasSeen(String key) =>
      completedTours.contains(key) || dismissedTips.contains(key);

  /// Check if a specific tour is completed
  bool isTourCompleted(String tourKey) => completedTours.contains(tourKey);

  /// Check if a specific tip is dismissed
  bool isTipDismissed(String tipKey) => dismissedTips.contains(tipKey);

  /// Minimum hours between showing tours
  static const int tourCooldownHours = 1;

  /// Returns true if enough time has passed since last tour
  bool get canShowTour {
    if (lastTourShown == null) return true;
    final hoursSinceLastTour =
        DateTime.now().difference(lastTourShown!).inHours;
    return hoursSinceLastTour >= tourCooldownHours;
  }

  /// Check if there was an error loading progress
  bool get hasError => error != null;

  @override
  String toString() =>
      'TourProgress(tours: ${completedTours.length}, tips: ${dismissedTips.length}, loaded: $isLoaded)';
}
