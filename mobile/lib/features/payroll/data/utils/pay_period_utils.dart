import '../models/pay_period_model.dart';

class PayPeriodUtils {
  /// Determines the most relevant "active" pay period for display.
  /// 
  /// Logic:
  /// 1. Prioritizes the period that encompasses the current date (Today).
  ///    (Only considers 'active' or 'draft' or 'processing' periods).
  /// 2. Future periods (Upcoming).
  /// 3. Fallback: Returns the earliest open/draft period (sorted by start date).
  /// 4. Returns null if no open/draft periods exist.
  static PayPeriod? getNextPayrollPeriod(List<PayPeriod> periods) {
    // Filter for open/draft periods
    final openPeriods = periods
        .where((p) => 
          p.status == PayPeriodStatus.active || 
          p.status == PayPeriodStatus.draft ||
          p.status == PayPeriodStatus.processing
        )
        .toList();
    
    if (openPeriods.isEmpty) return null;

    final now = DateTime.now();
    
    // 1. Try to find CURRENT period (today is within start/end)
    try {
      final current = openPeriods.firstWhere((p) => 
        p.startDate.isBefore(now) && p.endDate.add(const Duration(days: 1)).isAfter(now)
      );
      return current;
    } catch (_) {
      // 2. Try to find FUTURE periods (Upcoming)
      final futurePeriods = openPeriods.where((p) => p.startDate.isAfter(now)).toList();
      if (futurePeriods.isNotEmpty) {
        futurePeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
        return futurePeriods.first;
      }

      // 3. Fallback to earliest open period (Overdue)
      openPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
      return openPeriods.firstOrNull;
    }
  }

  /// Determines if the "Initialize Pay Periods" card should be shown.
  /// 
  /// Logic:
  /// - If any future periods exist (Draft/Active/Processing), return NULL (Hide card).
  /// - If Current Year has no periods -> Initialize Current Year.
  /// - If Current Year exists but is fully closed (or empty active) -> Initialize Next Year.
  static int? getYearToInitialize(List<PayPeriod> allPeriods) {
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = currentYear + 1;

    // Check for ANY future periods (Draft/Active/Processing) regardless of year
    final hasFuturePeriods = allPeriods.any((p) => 
      p.startDate.isAfter(now) && 
      (p.status == PayPeriodStatus.draft || p.status == PayPeriodStatus.active)
    );

    // If we have future active periods, we probably don't need to force initialization
    if (hasFuturePeriods) return null;
    
    // Check if Current Year has periods
    final currentYearPeriods = allPeriods.where((p) => p.startDate.year == currentYear).toList();
    
    if (currentYearPeriods.isEmpty) {
      return currentYear; // Case 1: Initialize Current Year (e.g. fresh install or new year started with no data)
    }

    // Check if Next Year has periods
    final nextYearPeriods = allPeriods.where((p) => p.startDate.year == nextYear).toList();
    if (nextYearPeriods.isNotEmpty) {
      return null; // Next year already initialized
    }

    // If Current Year is fully completed/closed -> Suggest Next Year
    // OR if we are just simply done with all current active periods.
    final hasActiveCurrentYear = currentYearPeriods.any((p) => 
      p.status == PayPeriodStatus.active || 
      p.status == PayPeriodStatus.draft || 
      p.status == PayPeriodStatus.processing
    );

    if (!hasActiveCurrentYear) {
      return nextYear; // Case 2: All current year periods are done. Ready for next year.
    }

    return null;
  }
}
